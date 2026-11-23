import 'package:material_ui/material_ui.dart';

/// Small labeled metric card used on room and tenant detail screens.
class RoomInfoCard extends StatelessWidget {
  const RoomInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.horizontal = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final content = <Widget>[
      Icon(icon, size: 18, color: scheme.primary),
      const SizedBox(width: 8),
      Text(
        label,
        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      if (!horizontal) ...[
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: horizontal
            ? Row(
                children: <Widget>[
                  ...content,
                  const Spacer(),
                  Text(
                    value,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              ),
      ),
    );
  }
}
