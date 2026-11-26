import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/payment.dart';
import 'proof_image_dialog.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

/// Owner review card for a tenant's submitted proof of payment.
class OwnerPaymentCard extends StatelessWidget {
  const OwnerPaymentCard({
    super.key,
    required this.payment,
    required this.tenantName,
    required this.roomName,
    this.tenantPhotoUrl,
    this.busy = false,
    this.onVerify,
    this.onReject,
  });

  final Payment payment;
  final String tenantName;
  final String roomName;
  final String? tenantPhotoUrl;
  final bool busy;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pending = payment.status == PaymentStatus.pending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                StatusChip.payment(payment.status),
                const Spacer(),
                Text(
                  AppHelpers.formatDate(payment.createdAt),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: payment.proofUrl.isEmpty
                        ? Container(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: payment.proofUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: scheme.surfaceContainerHighest,
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppHelpers.formatCurrency(payment.amount),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rent for ${AppHelpers.formatMonth(payment.month)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          UserAvatar(
                            name: tenantName,
                            photoUrl: tenantPhotoUrl,
                            radius: 11,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tenantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: payment.proofUrl.isEmpty
                    ? null
                    : () => showProofImage(context, payment.proofUrl),
                icon: const Icon(Icons.zoom_in_rounded, size: 18),
                label: const Text('View proof'),
              ),
            ),
            if (pending) ...[
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onVerify,
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify'),
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
