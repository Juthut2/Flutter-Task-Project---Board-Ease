import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../core/owner_stats.dart';
import 'stat_card.dart';

/// Two-column dashboard metric grid.
class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({
    super.key,
    required this.stats,
    required this.onOpenReservations,
  });

  final OwnerStats stats;
  final VoidCallback onOpenReservations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        final cards = <Widget>[
          StatCard(
            label: 'Total rooms',
            value: '${stats.totalRooms}',
            icon: Icons.home_work_outlined,
            color: scheme.primary,
            caption: '${stats.reservedRooms} reserved',
          ),
          StatCard(
            label: 'Available',
            value: '${stats.availableRooms}',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF137A5B),
            caption: 'Ready to reserve',
          ),
          StatCard(
            label: 'Occupied',
            value: '${stats.occupiedRooms}',
            icon: Icons.people_outline_rounded,
            color: const Color(0xFF2563EB),
            caption: 'Tenants assigned',
          ),
          StatCard(
            label: 'Pending requests',
            value: '${stats.pendingReservations}',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFB26A00),
            caption: 'Awaiting your review',
            onTap: onOpenReservations,
          ),
          StatCard(
            label: 'Monthly collections',
            value: AppHelpers.formatCompactCurrency(stats.monthlyCollections),
            icon: Icons.payments_outlined,
            color: scheme.tertiary,
            caption: 'Verified this month',
          ),
          StatCard(
            label: 'Overdue tenants',
            value: '${stats.overdueTenants}',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFB3261E),
            caption: 'No payment this month',
          ),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final card in cards)
              SizedBox(width: width, height: 142, child: card),
          ],
        );
      },
    );
  }
}
