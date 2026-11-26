import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

/// Celebration dialog shown after a successful reservation, payment, or
/// maintenance submission.
class SuccessDialog extends StatelessWidget {
  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'Done',
  });

  final String title;
  final String message;
  final String buttonLabel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Done',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Lottie.asset(
              'assets/animations/success.json',
              width: 150,
              height: 150,
              repeat: false,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.check_circle_rounded,
                size: 104,
                color: scheme.primary,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
