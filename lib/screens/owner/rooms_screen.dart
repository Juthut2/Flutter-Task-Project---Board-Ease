import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../services/room_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/room_card.dart';
import 'room_detail_screen.dart';
import 'room_form_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  RoomStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Room> _filtered(List<Room> rooms) {
    final query = _query.trim().toLowerCase();
    return rooms.where((room) {
      if (_statusFilter != null && room.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      return room.name.toLowerCase().contains(query) ||
          room.fullAddress.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openForm({Room? room}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RoomFormScreen(ownerId: user.uid, room: room),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(room == null ? 'Room added.' : 'Room updated.')),
      );
    }
  }

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
          'Delete "${room.name}"? This cannot be undone. Existing '
          'reservations and payment records are kept for your records.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<RoomsProvider>().deleteRoom(room.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room deleted.')));
    } on RoomFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openDetail(Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailScreen(roomId: room.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomsProvider>();
    final rooms = _filtered(provider.rooms);
    final hasRooms = provider.rooms.isNotEmpty;

    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by room name or address',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                for (final status in RoomStatus.values) ...<Widget>[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: status.label,
                    selected: _statusFilter == status,
                    onSelected: () => setState(() => _statusFilter = status),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                provider.retry();
                await Future<void>.delayed(const Duration(milliseconds: 600));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                children: <Widget>[
                  if (provider.errorMessage != null)
                    ErrorView(
                      message: provider.errorMessage!,
                      onRetry: provider.retry,
                    ),
                  if (provider.isLoading && !hasRooms)
                    const LoadingView(message: 'Loading your rooms...')
                  else if (rooms.isEmpty)
                    EmptyState(
                      icon: hasRooms
                          ? Icons.search_off_rounded
                          : Icons.home_work_outlined,
                      title: hasRooms ? 'No matching rooms' : 'No rooms yet',
                      message: hasRooms
                          ? 'Try a different search or status filter.'
                          : 'Add your first room with photos, rent, and a '
                                'complete address.',
                      action: hasRooms
                          ? null
                          : FilledButton.icon(
                              onPressed: () => _openForm(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add room'),
                            ),
                    )
                  else
                    for (final room in rooms) ...<Widget>[
                      RoomCard(
                        room: room,
                        onTap: () => _openDetail(room),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Room actions',
                          iconSize: 20,
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openForm(room: room);
                            } else if (value == 'delete') {
                              _deleteRoom(room);
                            }
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit room'),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete room'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_home_rounded),
        label: const Text('Add room'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
