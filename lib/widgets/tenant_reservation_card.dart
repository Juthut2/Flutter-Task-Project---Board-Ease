import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'status_chip.dart';

/// Tenant-facing reservation summary with an optional cancel action.
class TenantReservationCard extends StatelessWidget {
  const TenantReservationCard({
    super.key,
    required this.reservation,
    this.room,
    this.busy = false,
    this.onCancel,
  });

  final Reservation reservation;
  final Room? room;
  final bool busy;
  final VoidCallback? onCancel;

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
                StatusChip.reservation(reservation.status),
                const Spacer(),
                Text(
                  AppHelpers.formatDate(reservation.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              room?.name ?? 'Room unavailable',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _statusMessage(),
              style: textTheme.bodySmall?.copyWith(
                color: reservation.status == ReservationStatus.declined
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.event_available_outlined,
                  size: 17,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Move-in ${AppHelpers.formatDate(reservation.moveInDate)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (reservation.status == ReservationStatus.pending) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: busy ? null : onCancel,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusMessage() {
    return switch (reservation.status) {
      ReservationStatus.pending =>
        'Waiting for the owner to review your request.',
      ReservationStatus.approved =>
        'Approved. Submit your proof of payment from the Payments tab.',
      ReservationStatus.declined =>
        'The owner declined this request. Browse other rooms anytime.',
      ReservationStatus.cancelled => 'You cancelled this request.',
    };
  }
}
