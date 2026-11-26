import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/owner_stats.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/payments_provider.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/complete_profile_banner.dart';
import '../../widgets/dashboard_attention_card.dart';
import '../../widgets/dashboard_greeting_card.dart';
import '../../widgets/dashboard_stats_grid.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../shared/profile_screen.dart';
import 'overdue_tenants_screen.dart';
import 'room_detail_screen.dart';
import 'room_form_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.onOpenRooms,
    required this.onOpenReservations,
  });

  final VoidCallback onOpenRooms;
  final VoidCallback onOpenReservations;

  void _refresh(BuildContext context) {
    context.read<RoomsProvider>().retry();
    context.read<ReservationsProvider>().retry();
    context.read<PaymentsProvider>().retry();
    context.read<MaintenanceProvider>().retry();
  }

  Future<void> _refreshAsync(BuildContext context) async {
    _refresh(context);
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final roomsProvider = context.watch<RoomsProvider>();
    final reservationsProvider = context.watch<ReservationsProvider>();
    final paymentsProvider = context.watch<PaymentsProvider>();
    final stats = OwnerStats.compute(
      rooms: roomsProvider.rooms,
      reservations: reservationsProvider.reservations,
      payments: paymentsProvider.payments,
    );
    final error =
        roomsProvider.errorMessage ??
        reservationsProvider.errorMessage ??
        paymentsProvider.errorMessage;
    final isLoading = roomsProvider.isLoading && roomsProvider.rooms.isEmpty;

    return RefreshIndicator(
      onRefresh: () => _refreshAsync(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          if (!user.hasCompleteProfile) ...<Widget>[
            CompleteProfileBanner(
              onComplete: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileScreen(startInEditMode: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          DashboardGreetingCard(name: user.name, roomCount: stats.totalRooms),
          if (error != null) ...[
            const SizedBox(height: 16),
            ErrorView(message: error, onRetry: () => _refresh(context)),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Overview',
            subtitle: 'Live totals from your rooms and requests',
            action: TextButton.icon(
              onPressed: () => _refresh(context),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LoadingView(message: 'Loading your dashboard...')
          else
            DashboardStatsGrid(
              stats: stats,
              onOpenReservations: onOpenReservations,
              onOpenOverdue: () => _openOverdue(context),
            ),
          const SizedBox(height: 22),
          SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RoomFormScreen(ownerId: user.uid),
                    ),
                  ),
                  icon: const Icon(Icons.add_home_rounded),
                  label: const Text('Add room'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenReservations,
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text('Requests (${stats.pendingReservations})'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          DashboardAttentionCard(
            pending: stats.pendingReservations,
            overdue: stats.overdueTenants,
            onOpenReservations: onOpenReservations,
            onOpenOverdue: () => _openOverdue(context),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Your rooms',
            subtitle: stats.totalRooms == 0
                ? 'Add your first room to start accepting tenants'
                : '${stats.totalRooms} total, ${stats.availableRooms} available',
            action: TextButton(
              onPressed: onOpenRooms,
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 10),
          if (roomsProvider.rooms.isEmpty && !isLoading)
            EmptyState(
              icon: Icons.home_work_outlined,
              title: 'No rooms yet',
              message:
                  'Create a room with photos, rent, and a full PSGC address '
                  'so tenants can find it.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomFormScreen(ownerId: user.uid),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first room'),
              ),
            )
          else
            for (final room in roomsProvider.rooms.take(3)) ...<Widget>[
              RoomCard(room: room, onTap: () => _openRoom(context, room)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  void _openRoom(BuildContext context, Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailScreen(roomId: room.id),
      ),
    );
  }

  void _openOverdue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OverdueTenantsScreen()),
    );
  }
}
