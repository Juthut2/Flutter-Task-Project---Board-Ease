import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../core/tenant_rental.dart';
import 'status_chip.dart';

/// Active rental summary with this month's payment state.
class RentalSummaryCard extends StatelessWidget {
  const RentalSummaryCard({
    super.key,
    required this.rental,
    required this.onSubmitPayment,
    required this.onViewRoom,
  });

  final TenantRental rental;
  final VoidCallback onSubmitPayment;
  final VoidCallback onViewRoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    rental.room.name.isEmpty ? 'Your room' : rental.room.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _PaymentStateChip(rental: rental),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              rental.room.fullAddress.isEmpty
                  ? 'Address not set'
                  : rental.room.fullAddress,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Metric(
                    label: 'Monthly rent',
                    value: AppHelpers.formatCurrency(rental.room.monthlyRate),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Deposit',
                    value: AppHelpers.formatCurrency(rental.room.deposit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Line(
              icon: Icons.event_available_outlined,
              text:
                  'Move-in ${AppHelpers.formatDate(rental.reservation.moveInDate)}',
            ),
            const SizedBox(height: 6),
            _Line(
              icon: Icons.calendar_month_outlined,
              text: rental.isPaid
                  ? 'Next rent due ${AppHelpers.formatMonth(rental.dueMonth)}'
                  : 'Rent due for ${AppHelpers.formatMonth(rental.dueMonth)}',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewRoom,
                    child: const Text('View room'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: rental.hasPendingPayment
                        ? null
                        : onSubmitPayment,
                    child: Text(
                      rental.isPaid
                          ? 'Pay next month'
                          : rental.hasPendingPayment
                          ? 'Awaiting review'
                          : 'Submit payment',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentStateChip extends StatelessWidget {
  const _PaymentStateChip({required this.rental});

  final TenantRental rental;

  @override
  Widget build(BuildContext context) {
    if (rental.isPaid) {
      return const StatusChip(
        label: 'Paid',
        color: Color(0xFF137A5B),
        icon: Icons.verified_outlined,
      );
    }
    if (rental.hasPendingPayment) {
      return const StatusChip(
        label: 'Under review',
        color: Color(0xFFB26A00),
        icon: Icons.hourglass_top_rounded,
      );
    }
    return const StatusChip(
      label: 'Due',
      color: Color(0xFFB3261E),
      icon: Icons.warning_amber_rounded,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
