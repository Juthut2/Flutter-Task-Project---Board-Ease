import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/owner_stats.dart';
import '../../providers/payments_provider.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_header.dart';
import 'room_detail_screen.dart';
import 'tenant_detail_screen.dart';

/// Occupied rooms without a verified payment for the current month.
class OverdueTenantsScreen extends StatefulWidget {
  const OverdueTenantsScreen({super.key});

  @override
  State<OverdueTenantsScreen> createState() => _OverdueTenantsScreenState();
}

class _OverdueTenantsScreenState extends State<OverdueTenantsScreen> {
  int _visibleCount = AppConstants.pageSize;

  @override
  Widget build(BuildContext context) {
    final roomsProvider = context.watch<RoomsProvider>();
    final paymentsProvider = context.watch<PaymentsProvider>();
    final reservationsProvider = context.watch<ReservationsProvider>();
    final tenantsProvider = context.watch<TenantsProvider>();

    final stats = OwnerStats.compute(
      rooms: roomsProvider.rooms,
      reservations: reservationsProvider.reservations,
      payments: paymentsProvider.payments,
    );
    final error =
        roomsProvider.errorMessage ??
        paymentsProvider.errorMessage ??
        reservationsProvider.errorMessage;
    final loading =
        (roomsProvider.isLoading && roomsProvider.rooms.isEmpty) ||
        (paymentsProvider.isLoading && paymentsProvider.payments.isEmpty);
    final overdue = stats.overdueRooms;
    final visible = overdue.take(_visibleCount).toList();
    final remaining = overdue.length - visible.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Overdue tenants')),
      body: RefreshIndicator(
        onRefresh: () async {
          roomsProvider.retry();
          paymentsProvider.retry();
          reservationsProvider.retry();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            if (error != null)
              ErrorView(
                message: error,
                onRetry: () {
                  roomsProvider.retry();
                  paymentsProvider.retry();
                  reservationsProvider.retry();
                },
              ),
            if (loading)
              const LoadingView(message: 'Checking rent payments...')
            else if (overdue.isEmpty)
              const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'No overdue tenants',
                message:
                    'Every occupied room has a verified payment for this '
                    'month.',
              )
            else ...[
              SectionHeader(
                title:
                    '${stats.overdueTenants} overdue '
                    '${stats.overdueTenants == 1 ? 'tenant' : 'tenants'}',
                subtitle:
                    'No verified payment for '
                    '${AppHelpers.formatMonth(AppHelpers.currentMonth())}',
              ),
              const SizedBox(height: 10),
              for (final room in visible) ...<Widget>[
                _OverdueCard(
                  roomName: room.name.isEmpty ? 'Untitled room' : room.name,
                  tenantName:
                      tenantsProvider.tenantById(room.tenantId ?? '')?.name ??
                      'Tenant',
                  monthlyRate: room.monthlyRate,
                  onOpenTenant: room.tenantId == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TenantDetailScreen(tenantId: room.tenantId!),
                          ),
                        ),
                  onOpenRoom: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RoomDetailScreen(roomId: room.id),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (remaining > 0)
                LoadMoreButton(
                  remaining: remaining,
                  onPressed: () =>
                      setState(() => _visibleCount += AppConstants.pageSize),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  const _OverdueCard({
    required this.roomName,
    required this.tenantName,
    required this.monthlyRate,
    this.onOpenTenant,
    required this.onOpenRoom,
  });

  final String roomName;
  final String tenantName;
  final double monthlyRate;
  final VoidCallback? onOpenTenant;
  final VoidCallback onOpenRoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tenantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  AppHelpers.formatCurrency(monthlyRate),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              roomName,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                if (onOpenTenant != null)
                  TextButton(
                    onPressed: onOpenTenant,
                    child: const Text('View tenant'),
                  ),
                TextButton(
                  onPressed: onOpenRoom,
                  child: const Text('View room'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
