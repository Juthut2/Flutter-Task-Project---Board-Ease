import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/tenant_rental.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_payments_provider.dart';
import '../../providers/tenant_reservations_provider.dart';
import '../../providers/tenant_rooms_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/payment_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import 'submit_payment_screen.dart';

/// Tenant payment history with the current rent due summary.
class TenantPaymentsScreen extends StatefulWidget {
  const TenantPaymentsScreen({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  State<TenantPaymentsScreen> createState() => _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends State<TenantPaymentsScreen> {
  int _visibleCount = AppConstants.pageSize;

  Future<void> _submitPayment(BuildContext context, TenantRental rental) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SubmitPaymentScreen(rental: rental),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomsProvider = context.watch<TenantRoomsProvider>();
    final reservationsProvider = context.watch<TenantReservationsProvider>();
    final paymentsProvider = context.watch<TenantPaymentsProvider>();
    final user = context.watch<AuthProvider>().user;
    final payments = paymentsProvider.payments;
    final visiblePayments = payments.take(_visibleCount).toList();
    final remaining = payments.length - visiblePayments.length;

    final rental = user == null
        ? null
        : TenantRentalSummary.active(
            tenantId: user.uid,
            reservations: reservationsProvider.reservations,
            rooms: roomsProvider.rooms,
            payments: payments,
          );

    final error =
        paymentsProvider.errorMessage ??
        roomsProvider.errorMessage ??
        reservationsProvider.errorMessage;

    final loading =
        (paymentsProvider.isLoading && payments.isEmpty) ||
        (roomsProvider.isLoading && roomsProvider.rooms.isEmpty) ||
        (reservationsProvider.isLoading &&
            reservationsProvider.reservations.isEmpty);

    if (loading) {
      return const LoadingView(message: 'Loading your payments...');
    }

    return RefreshIndicator(
      onRefresh: () async {
        paymentsProvider.retry();
        roomsProvider.retry();
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
                paymentsProvider.retry();
                roomsProvider.retry();
                reservationsProvider.retry();
              },
            ),
          if (rental == null)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No rent due',
              message:
                  'Once a reservation is approved, your monthly rent and '
                  'payment history appear here.',
              action: FilledButton.icon(
                onPressed: widget.onBrowse,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse rooms'),
              ),
            )
          else
            _DueCard(
              rental: rental,
              onSubmit: () => _submitPayment(context, rental),
            ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Payment history',
            subtitle: 'Proof of payment you have submitted',
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No payments yet',
              message: 'Your submitted proofs of payment will be listed here.',
            )
          else
            for (final payment in visiblePayments) ...<Widget>[
              PaymentCard(payment: payment),
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
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.rental, required this.onSubmit});

  final TenantRental rental;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = rental.isPaid
        ? 'This month is paid. Next rent is due '
              '${AppHelpers.formatMonth(rental.dueMonth)}. You can submit '
              'early if you like.'
        : rental.hasPendingPayment
        ? 'Your payment is waiting for owner verification.'
        : 'Submit your proof of payment for this month.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.calendar_month_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rental.isPaid
                        ? 'Next rent: '
                              '${AppHelpers.formatMonth(rental.dueMonth)}'
                        : 'Rent for '
                              '${AppHelpers.formatMonth(rental.dueMonth)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _chip(),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    AppHelpers.formatCurrency(rental.room.monthlyRate),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: rental.hasPendingPayment ? null : onSubmit,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    rental.hasPendingPayment
                        ? 'Awaiting review'
                        : 'Submit proof',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip() {
    if (rental.isPaid) {
      return const StatusChip(
        label: 'Upcoming',
        color: Color(0xFF2563EB),
        icon: Icons.schedule_rounded,
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
