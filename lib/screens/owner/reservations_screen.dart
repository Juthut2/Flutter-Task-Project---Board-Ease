import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../models/reservation.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../services/reservation_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/success_dialog.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _pendingOnly = true;
  String? _busyId;
  int _visibleCount = AppConstants.pageSize;

  Future<void> _decide(Reservation reservation, {required bool approve}) async {
    final roomsProvider = context.read<RoomsProvider>();
    final tenantsProvider = context.read<TenantsProvider>();
    final room = roomsProvider.roomById(reservation.roomId);
    final tenant = tenantsProvider.tenantById(reservation.tenantId);
    final who = tenant?.name ?? 'this tenant';
    final what = room?.name ?? 'this room';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve request?' : 'Decline request?'),
        content: Text(
          approve
              ? 'Approve $who for $what? The room will be marked occupied '
                    'and removed from available listings.'
              : 'Decline the request from $who for $what? The room stays '
                    'available for other tenants.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(approve ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = reservation.id);
    try {
      await context.read<ReservationsProvider>().decide(
        reservation,
        approve: approve,
      );
      if (!mounted) return;
      if (approve) {
        await SuccessDialog.show(
          context,
          title: 'Reservation approved!',
          message:
              'The room is now marked occupied and the tenant can start '
              'submitting rent payments.',
        );
      } else {
        AppHelpers.showSnackBar(context, 'Reservation declined.');
      }
    } on ReservationFailure catch (error) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Could not update the request. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsProvider = context.watch<RoomsProvider>();
    final reservationsProvider = context.watch<ReservationsProvider>();
    final tenantsProvider = context.watch<TenantsProvider>();
    final all = reservationsProvider.forRooms(roomsProvider.rooms);
    final pending = all.where((item) => item.isPending).toList();
    final visible = _pendingOnly ? pending : all;
    visible.sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    final paged = visible.take(_visibleCount).toList();
    final remaining = visible.length - paged.length;
    final isLoading =
        (reservationsProvider.isLoading && all.isEmpty) ||
        (roomsProvider.isLoading && roomsProvider.rooms.isEmpty);
    final error =
        reservationsProvider.errorMessage ?? roomsProvider.errorMessage;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  pending.isEmpty
                      ? 'No pending requests'
                      : '${pending.length} pending '
                            '${pending.length == 1 ? 'request' : 'requests'}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              FilterChip(
                label: const Text('Pending only'),
                selected: _pendingOnly,
                onSelected: (value) => setState(() {
                  _pendingOnly = value;
                  _visibleCount = AppConstants.pageSize;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
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
                      reservationsProvider.retry();
                      roomsProvider.retry();
                    },
                  ),
                if (isLoading)
                  const LoadingView(message: 'Loading reservation requests...')
                else if (visible.isEmpty)
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    title: _pendingOnly
                        ? 'No pending requests'
                        : 'No reservation requests yet',
                    message: _pendingOnly && all.isNotEmpty
                        ? 'Switch off "Pending only" to see past requests.'
                        : 'New tenant requests will appear here for review.',
                    action: _pendingOnly && all.isNotEmpty
                        ? OutlinedButton(
                            onPressed: () => setState(() {
                              _pendingOnly = false;
                              _visibleCount = AppConstants.pageSize;
                            }),
                            child: const Text('Show all requests'),
                          )
                        : null,
                  )
                else
                  for (final reservation in paged) ...<Widget>[
                    ReservationCard(
                      reservation: reservation,
                      room: roomsProvider.roomById(reservation.roomId),
                      tenant: tenantsProvider.tenantById(reservation.tenantId),
                      busy: _busyId == reservation.id,
                      onApprove: () => _decide(reservation, approve: true),
                      onDecline: () => _decide(reservation, approve: false),
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
}
