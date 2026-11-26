import 'package:material_ui/material_ui.dart';

/// Consistent 20-item pagination footer for long live lists.
class LoadMoreButton extends StatelessWidget {
  const LoadMoreButton({
    super.key,
    required this.onPressed,
    this.remaining,
    this.busy = false,
  });

  final VoidCallback onPressed;
  final int? remaining;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final suffix = remaining == null || remaining! <= 0
        ? ''
        : ' ($remaining more)';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more_rounded),
          label: Text(busy ? 'Loading...' : 'Load more$suffix'),
        ),
      ),
    );
  }
}
