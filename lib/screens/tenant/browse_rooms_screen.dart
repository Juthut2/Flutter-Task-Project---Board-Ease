import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_rooms_provider.dart';
import '../../widgets/complete_profile_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/room_card.dart';
import '../../widgets/tenant_filter_bar.dart';
import '../shared/profile_screen.dart';
import 'tenant_room_detail_screen.dart';

/// Tenant room directory with search, budget, and sort controls.
class BrowseRoomsScreen extends StatefulWidget {
  const BrowseRoomsScreen({super.key});

  @override
  State<BrowseRoomsScreen> createState() => _BrowseRoomsScreenState();
}

class _BrowseRoomsScreenState extends State<BrowseRoomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  double? _maxPrice;
  RoomSort _sort = RoomSort.newest;
  int _visibleCount = AppConstants.pageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Room> _visible(List<Room> rooms) {
    final query = _query.trim().toLowerCase();
    final filtered = rooms.where((room) {
      if (_maxPrice != null && room.monthlyRate > _maxPrice!) return false;
      if (query.isEmpty) return true;
      return room.name.toLowerCase().contains(query) ||
          room.fullAddress.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case RoomSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case RoomSort.priceLow:
        filtered.sort((a, b) => a.monthlyRate.compareTo(b.monthlyRate));
      case RoomSort.priceHigh:
        filtered.sort((a, b) => b.monthlyRate.compareTo(a.monthlyRate));
    }
    return filtered;
  }

  void _openRoom(Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TenantRoomDetailScreen(roomId: room.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<TenantRoomsProvider>();
    final available = provider.availableRooms;
    final rooms = _visible(available);
    final visible = rooms.take(_visibleCount).toList();
    final remaining = rooms.length - visible.length;
    final hasRooms = available.isNotEmpty;

    return Column(
      children: <Widget>[
        TenantFilterBar(
          searchController: _searchController,
          query: _query,
          maxPrice: _maxPrice,
          sort: _sort,
          onQueryChanged: (value) => setState(() {
            _query = value;
            _visibleCount = AppConstants.pageSize;
          }),
          onMaxPriceChanged: (value) => setState(() {
            _maxPrice = value;
            _visibleCount = AppConstants.pageSize;
          }),
          onSortChanged: (value) => setState(() {
            _sort = value;
            _visibleCount = AppConstants.pageSize;
          }),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: <Widget>[
                if (user != null && !user.hasCompleteProfile) ...<Widget>[
                  CompleteProfileBanner(
                    onComplete: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ProfileScreen(startInEditMode: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (provider.errorMessage != null)
                  ErrorView(
                    message: provider.errorMessage!,
                    onRetry: provider.retry,
                  ),
                if (provider.isLoading && !hasRooms)
                  const LoadingView(message: 'Finding available rooms...')
                else if (rooms.isEmpty)
                  EmptyState(
                    icon: hasRooms
                        ? Icons.search_off_rounded
                        : Icons.home_work_outlined,
                    title: hasRooms
                        ? 'No rooms match your filters'
                        : 'No rooms available yet',
                    message: hasRooms
                        ? 'Try a higher budget or a different search.'
                        : 'New rooms will appear here as soon as the owner '
                              'adds them.',
                  )
                else
                  for (final room in visible) ...<Widget>[
                    RoomCard(room: room, onTap: () => _openRoom(room)),
                    const SizedBox(height: 10),
                  ],
                if (remaining > 0)
                  LoadMoreButton(
                    remaining: remaining,
                    onPressed: () =>
                        setState(() => _visibleCount += AppConstants.pageSize),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
