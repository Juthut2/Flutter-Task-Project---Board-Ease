import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../services/room_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/room_detail_body.dart';
import 'room_form_screen.dart';
import 'tenant_detail_screen.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  Future<void> _markAvailable(BuildContext context, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark room available?'),
        content: const Text(
          'This clears the current tenant assignment and makes the room '
          'available for new reservations.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mark available'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<RoomsProvider>().updateRoom(
        room.copyWith(status: RoomStatus.available, clearTenant: true),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Room is now available.')));
    } on RoomFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _delete(BuildContext context, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text('Delete "${room.name}"? This cannot be undone.'),
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
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<RoomsProvider>().deleteRoom(room.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Room deleted.')));
    } on RoomFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomsProvider>();
    final room = provider.roomById(roomId);
    if (room == null) {
      final error = provider.errorMessage;
      return Scaffold(
        appBar: AppBar(title: const Text('Room details')),
        body: provider.isLoading
            ? const LoadingView(message: 'Loading room...')
            : error != null
            ? ErrorView(message: error, onRetry: provider.retry)
            : const EmptyState(
                icon: Icons.home_work_outlined,
                title: 'Room not found',
                message: 'This room may have been deleted.',
              ),
      );
    }

    final owner = context.watch<AuthProvider>().user;
    final tenant = room.tenantId == null
        ? null
        : context.watch<TenantsProvider>().tenantById(room.tenantId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room details'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit room',
            onPressed: owner == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          RoomFormScreen(ownerId: owner.uid, room: room),
                    ),
                  ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: RoomDetailBody(
        room: room,
        tenant: tenant,
        onEdit: owner == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      RoomFormScreen(ownerId: owner.uid, room: room),
                ),
              ),
        onMarkAvailable: room.status == RoomStatus.available
            ? null
            : () => _markAvailable(context, room),
        onDelete: () => _delete(context, room),
        onViewTenant: tenant == null
            ? () {}
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TenantDetailScreen(tenantId: tenant.uid),
                ),
              ),
      ),
    );
  }
}
