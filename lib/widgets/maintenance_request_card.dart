import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/maintenance_request.dart';
import 'proof_image_dialog.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

/// Maintenance request summary shared by tenant and owner views.
class MaintenanceRequestCard extends StatelessWidget {
  const MaintenanceRequestCard({
    super.key,
    required this.request,
    required this.roomName,
    this.tenantName,
    this.tenantPhotoUrl,
    this.busy = false,
    this.onStatusChanged,
  });

  final MaintenanceRequest request;
  final String roomName;
  final String? tenantName;
  final String? tenantPhotoUrl;
  final bool busy;
  final ValueChanged<MaintenanceStatus>? onStatusChanged;

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
                StatusChip.maintenance(request.status),
                const Spacer(),
                Text(
                  AppHelpers.formatDate(request.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (onStatusChanged != null) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<MaintenanceStatus>(
                    tooltip: 'Update status',
                    enabled: !busy,
                    onSelected: onStatusChanged,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.more_vert_rounded),
                    itemBuilder: (_) => <PopupMenuEntry<MaintenanceStatus>>[
                      for (final status in MaintenanceStatus.values)
                        if (status != request.status)
                          PopupMenuItem<MaintenanceStatus>(
                            value: status,
                            child: Text('Mark ${status.label.toLowerCase()}'),
                          ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.title.isEmpty ? 'Maintenance request' : request.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  Icons.home_work_outlined,
                  size: 17,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    roomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (tenantName != null) ...<Widget>[
                  const SizedBox(width: 8),
                  UserAvatar(
                    name: tenantName!,
                    photoUrl: tenantPhotoUrl,
                    radius: 10,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tenantName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (request.photoUrl != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => showProofImage(context, request.photoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: request.photoUrl!,
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
