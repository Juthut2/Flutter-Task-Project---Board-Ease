import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/payment.dart';
import 'proof_image_dialog.dart';
import 'status_chip.dart';

/// Payment history row with a tappable proof-of-payment thumbnail.
class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: payment.proofUrl.isEmpty
            ? null
            : () => showProofImage(context, payment.proofUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
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
                          placeholder: (_, _) =>
                              Container(color: scheme.surfaceContainerHighest),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppHelpers.formatCurrency(payment.amount),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusChip.payment(payment.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rent for ${AppHelpers.formatMonth(payment.month)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submitted ${AppHelpers.formatDate(payment.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (payment.status == PaymentStatus.rejected) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Rejected. Submit a new proof of payment.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
