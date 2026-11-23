import 'package:material_ui/material_ui.dart';

/// Owner actions shown at the bottom of the room detail screen.
class RoomOwnerActions extends StatelessWidget {
  const RoomOwnerActions({
    super.key,
    this.onEdit,
    this.onMarkAvailable,
    required this.onDelete,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onMarkAvailable;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit room'),
        ),
        if (onMarkAvailable != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onMarkAvailable,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Mark as available'),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete room'),
        ),
      ],
    );
  }
}
