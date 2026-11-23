import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/room.dart';
import 'status_chip.dart';

/// Room summary card shared by the owner's room list and tenant browse screen.
class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, this.onTap, this.trailing});

  final Room room;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: room.coverPhoto.isEmpty
                      ? _PhotoPlaceholder(color: scheme.surfaceContainerHighest)
                      : CachedNetworkImage(
                          imageUrl: room.coverPhoto,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _PhotoPlaceholder(
                            color: scheme.surfaceContainerHighest,
                          ),
                          errorWidget: (_, _, _) => _PhotoPlaceholder(
                            color: scheme.surfaceContainerHighest,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            room.name.isEmpty ? 'Untitled room' : room.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        StatusChip.room(room.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${room.capacity} ${room.capacity == 1 ? 'person' : 'people'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.fullAddress.isEmpty
                          ? 'Address not set'
                          : room.fullAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppHelpers.formatCurrency(room.monthlyRate)} / month',
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Icon(
        Icons.home_work_outlined,
        size: 30,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
