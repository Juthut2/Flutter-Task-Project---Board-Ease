import 'package:material_ui/material_ui.dart';

/// Dashboard card summarizing pending requests and overdue tenants.
class DashboardAttentionCard extends StatelessWidget {
  const DashboardAttentionCard({
    super.key,
    required this.pending,
    required this.overdue,
    required this.onOpenReservations,
  });

  final int pending;
  final int overdue;
  final VoidCallback onOpenReservations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasWork = pending > 0 || overdue > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  hasWork
                      ? Icons.notifications_active_outlined
                      : Icons.task_alt_rounded,
                  color: hasWork ? const Color(0xFFB26A00) : scheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  hasWork ? 'Needs attention' : 'All caught up',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasWork
                  ? _message()
                  : 'No pending requests or overdue tenants right now.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (pending > 0) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onOpenReservations,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Review requests'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _message() {
    final parts = <String>[];
    if (pending > 0) {
      parts.add(
        '$pending reservation ${pending == 1 ? 'request' : 'requests'}',
      );
    }
    if (overdue > 0) {
      parts.add('$overdue overdue ${overdue == 1 ? 'tenant' : 'tenants'}');
    }
    final verb = parts.length == 1 ? 'needs' : 'need';
    return '${parts.join(' and ')} $verb your review.';
  }
}
