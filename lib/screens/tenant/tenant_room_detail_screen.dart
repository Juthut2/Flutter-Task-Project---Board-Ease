import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_reservations_provider.dart';
import '../../providers/tenant_rooms_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/tenant_room_detail_body.dart';
import 'reserve_room_screen.dart';

/// Full room details for tenants with a reservation entry point.
class TenantRoomDetailScreen extends StatelessWidget {
  const TenantRoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  Future<void> _reserve(BuildContext context, Room room) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ReserveRoomScreen(room: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomsProvider = context.watch<TenantRoomsProvider>();
    final reservations = context.watch<TenantReservationsProvider>();
    final room = roomsProvider.roomById(roomId);
    if (room == null) {
      final error = roomsProvider.errorMessage;
      return Scaffold(
        appBar: AppBar(title: const Text('Room details')),
        body: roomsProvider.isLoading
            ? const LoadingView(message: 'Loading room...')
            : error != null
            ? ErrorView(message: error, onRetry: roomsProvider.retry)
            : const EmptyState(
                icon: Icons.home_work_outlined,
                title: 'Room not found',
                message: 'This room may no longer be listed.',
              ),
      );
    }

    final user = context.watch<AuthProvider>().user;
    final hasActiveRental =
        user != null &&
        roomsProvider.rooms.any(
          (item) =>
              item.tenantId == user.uid && item.status != RoomStatus.available,
        );
    final blocking = reservations.blockingForRoom(room.id);
    final canReserve = room.isAvailable && blocking == null && !hasActiveRental;

    return Scaffold(
      appBar: AppBar(title: const Text('Room details')),
      body: TenantRoomDetailBody(
        room: room,
        blocking: blocking,
        hasActiveRental: hasActiveRental,
        canReserve: canReserve,
        onReserve: () => _reserve(context, room),
      ),
    );
  }
}
