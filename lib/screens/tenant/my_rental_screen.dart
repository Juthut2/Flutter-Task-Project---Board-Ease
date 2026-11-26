import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/tenant_rental.dart';
import '../../models/reservation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_payments_provider.dart';
import '../../providers/tenant_reservations_provider.dart';
import '../../providers/tenant_rooms_provider.dart';
import '../../services/reservation_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/rental_summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tenant_reservation_card.dart';
import 'submit_payment_screen.dart';
import 'tenant_room_detail_screen.dart';

/// Tenant rental overview with request history and payment entry points.
class MyRentalScreen extends StatefulWidget {
  const MyRentalScreen({
    super.key,
    required this.onBrowse,
    required this.onOpenPayments,
  });

  final VoidCallback onBrowse;
  final VoidCallback onOpenPayments;

  @override
  State<MyRentalScreen> createState() => _MyRentalScreenState();
}

class _MyRentalScreenState extends State<MyRentalScreen> {
  String? _busyReservationId;

  Future<void> _cancel(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text(
          'The owner will no longer review this reservation request.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyReservationId = reservation.id);
    try {
      await context.read<TenantReservationsProvider>().cancel(reservation);
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Reservation request cancelled.');
    } on ReservationFailure catch (error) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Could not cancel the request. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyReservationId = null);
    }
  }

  Future<void> _submitPayment(TenantRental rental) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SubmitPaymentScreen(rental: rental),
      ),
    );
  }

  void _openRoom(String roomId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TenantRoomDetailScreen(roomId: roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomsProvider = context.watch<TenantRoomsProvider>();
    final reservationsProvider = context.watch<TenantReservationsProvider>();
    final paymentsProvider = context.watch<TenantPaymentsProvider>();
    final user = context.watch<AuthProvider>().user;
    final rooms = roomsProvider.rooms;
    final reservations = reservationsProvider.reservations;

    final rental = user == null
        ? null
        : TenantRentalSummary.active(
            tenantId: user.uid,
            reservations: reservations,
            rooms: rooms,
            payments: paymentsProvider.payments,
          );

    final requests = reservationsProvider.activeRequests
        .where((item) => item.id != rental?.reservation.id)
        .toList();
    final history = reservations
        .where(
          (item) =>
              item.status == ReservationStatus.declined ||
              item.status == ReservationStatus.cancelled,
        )
        .take(5)
        .toList();

    final error =
        reservationsProvider.errorMessage ??
        roomsProvider.errorMessage ??
        paymentsProvider.errorMessage;
    final loading =
        reservationsProvider.isLoading &&
        roomsProvider.isLoading &&
        reservations.isEmpty;

    if (loading) {
      return const LoadingView(message: 'Loading your rental...');
    }

    return RefreshIndicator(
      onRefresh: () async {
        roomsProvider.retry();
        reservationsProvider.retry();
        paymentsProvider.retry();
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
                reservationsProvider.retry();
                paymentsProvider.retry();
              },
            ),
          if (rental != null) ...[
            RentalSummaryCard(
              rental: rental,
              onSubmitPayment: () => _submitPayment(rental),
              onViewRoom: () => _openRoom(rental.room.id),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onOpenPayments,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View payment history'),
            ),
          ] else
            EmptyState(
              icon: Icons.home_work_outlined,
              title: 'No active rental yet',
              message:
                  'Reserve a room to see your rent, due dates, and payment '
                  'history here.',
              action: FilledButton.icon(
                onPressed: widget.onBrowse,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse rooms'),
              ),
            ),
          if (requests.isNotEmpty) ...[
            const SizedBox(height: 22),
            const SectionHeader(title: 'Your requests'),
            const SizedBox(height: 8),
            for (final reservation in requests) ...<Widget>[
              TenantReservationCard(
                reservation: reservation,
                room: roomsProvider.roomById(reservation.roomId),
                busy: _busyReservationId == reservation.id,
                onCancel: () => _cancel(reservation),
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'Recent history',
              subtitle: 'Declined and cancelled requests',
            ),
            const SizedBox(height: 8),
            for (final reservation in history) ...<Widget>[
              TenantReservationCard(
                reservation: reservation,
                room: roomsProvider.roomById(reservation.roomId),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}
