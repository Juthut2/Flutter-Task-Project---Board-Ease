import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/owner_stats.dart';
import '../../models/payment.dart';
import '../../providers/payments_provider.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/owner_payment_card.dart';
import '../../widgets/success_dialog.dart';
import 'overdue_tenants_screen.dart';

/// Owner payment review queue with verification and rejection actions.
class OwnerPaymentsScreen extends StatefulWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  State<OwnerPaymentsScreen> createState() => _OwnerPaymentsScreenState();
}

class _OwnerPaymentsScreenState extends State<OwnerPaymentsScreen> {
  PaymentStatus? _filter = PaymentStatus.pending;
  String? _busyId;
  int _visibleCount = AppConstants.pageSize;

  Future<void> _decide(Payment payment, {required bool approve}) async {
    final rooms = context.read<RoomsProvider>();
    final tenants = context.read<TenantsProvider>();
    final tenantName =
        tenants.tenantById(payment.tenantId)?.name ?? 'this tenant';
    final roomName = rooms.roomById(payment.roomId)?.name ?? 'this room';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Verify payment?' : 'Reject payment?'),
        content: Text(
          approve
              ? 'Mark ${AppHelpers.formatCurrency(payment.amount)} from '
                    '$tenantName for $roomName as verified?'
              : 'Reject the payment from $tenantName for $roomName? The '
                    'tenant can submit a new proof.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(approve ? 'Verify' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = payment.id);
    try {
      await context.read<PaymentsProvider>().decide(payment, approve: approve);
      if (!mounted) return;
      if (approve) {
        await SuccessDialog.show(
          context,
          title: 'Payment verified!',
          message:
              '${AppHelpers.formatCurrency(payment.amount)} from $tenantName '
              'is now recorded as paid.',
        );
      } else {
        AppHelpers.showSnackBar(context, 'Payment rejected.');
      }
    } on PaymentFailure catch (error) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Could not update the payment. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _openOverdue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OverdueTenantsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsProvider = context.watch<PaymentsProvider>();
    final roomsProvider = context.watch<RoomsProvider>();
    final tenantsProvider = context.watch<TenantsProvider>();
    final reservationsProvider = context.watch<ReservationsProvider>();

    final stats = OwnerStats.compute(
      rooms: roomsProvider.rooms,
      reservations: reservationsProvider.reservations,
      payments: paymentsProvider.payments,
    );
    final roomIds = roomsProvider.rooms.map((room) => room.id).toSet();
    final ownerPayments = paymentsProvider.payments
        .where((item) => roomIds.contains(item.roomId))
        .toList();
    final filtered = ownerPayments
        .where((item) => _filter == null || item.status == _filter)
        .toList();
    final visible = filtered.take(_visibleCount).toList();
    final remaining = filtered.length - visible.length;
    final error =
        paymentsProvider.errorMessage ??
        roomsProvider.errorMessage ??
        tenantsProvider.errorMessage;
    final loading =
        (paymentsProvider.isLoading && ownerPayments.isEmpty) ||
        (roomsProvider.isLoading && roomsProvider.rooms.isEmpty);

    return Column(
      children: <Widget>[
        if (stats.overdueTenants > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _OverdueBanner(
              count: stats.overdueTenants,
              onOpen: _openOverdue,
            ),
          ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              for (final option in <PaymentStatus?>[
                PaymentStatus.pending,
                PaymentStatus.verified,
                PaymentStatus.rejected,
                null,
              ]) ...<Widget>[
                if (option != PaymentStatus.pending) const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_filterLabel(option, ownerPayments)),
                  selected: _filter == option,
                  onSelected: (_) => setState(() {
                    _filter = option;
                    _visibleCount = AppConstants.pageSize;
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              paymentsProvider.retry();
              roomsProvider.retry();
              reservationsProvider.retry();
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: <Widget>[
                if (error != null)
                  ErrorView(
                    message: error,
                    onRetry: () {
                      paymentsProvider.retry();
                      roomsProvider.retry();
                    },
                  ),
                if (loading)
                  const LoadingView(message: 'Loading payments...')
                else if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _filter == PaymentStatus.pending
                        ? 'No payments to review'
                        : 'No payments here yet',
                    message: _filter == PaymentStatus.pending
                        ? 'Tenant proofs of payment will appear here for '
                              'verification.'
                        : 'Payments with this status will appear here.',
                  )
                else
                  for (final payment in visible) ...<Widget>[
                    OwnerPaymentCard(
                      payment: payment,
                      tenantName:
                          tenantsProvider.tenantById(payment.tenantId)?.name ??
                          'Tenant',
                      tenantPhotoUrl: tenantsProvider
                          .tenantById(payment.tenantId)
                          ?.photoUrl,
                      roomName:
                          roomsProvider.roomById(payment.roomId)?.name ??
                          'Room removed',
                      busy: _busyId == payment.id,
                      onVerify: () => _decide(payment, approve: true),
                      onReject: () => _decide(payment, approve: false),
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
            ),
          ),
        ),
      ],
    );
  }

  String _filterLabel(PaymentStatus? status, List<Payment> payments) {
    final label = status?.label ?? 'All';
    final count = status == null
        ? payments.length
        : payments.where((item) => item.status == status).length;
    return count == 0 ? label : '$label ($count)';
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'tenant has' : 'tenants have'} no '
                'verified payment this month.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onOpen, child: const Text('Review')),
          ],
        ),
      ),
    );
  }
}
