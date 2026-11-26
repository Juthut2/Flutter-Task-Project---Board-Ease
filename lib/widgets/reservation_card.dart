import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/app_user.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

/// Reservation summary with owner approval actions for pending requests.
class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    this.room,
    this.tenant,
    this.busy = false,
    this.onApprove,
    this.onDecline,
  });

  final Reservation reservation;
  final Room? room;
  final AppUser? tenant;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pending = reservation.status == ReservationStatus.pending;
    final roomUnavailable = room == null || !room!.isAvailable;

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
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UserAvatar(
                  name: tenant?.name ?? 'Tenant',
                  photoUrl: tenant?.photoUrl,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        tenant?.name ?? 'Tenant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        room?.name ?? 'Room removed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            if (tenant != null && tenant!.phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.phone_outlined,
                    size: 17,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tenant!.phone,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (pending && roomUnavailable) ...[
              const SizedBox(height: 10),
              Text(
                'This room is no longer available. Decline the request.',
                style: textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy || roomUnavailable ? null : onApprove,
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
