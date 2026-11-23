import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_banner.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.refreshEmailVerification();
    if (!mounted || verified) return;
    AppHelpers.showSnackBar(
      context,
      auth.errorMessage ?? 'Your email is not verified yet.',
      isError: true,
    );
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final sent = await auth.resendVerificationEmail();
    if (!mounted) return;
    if (sent) {
      _startCooldown();
      AppHelpers.showSnackBar(
        context,
        'Verification email sent. Check your inbox.',
      );
    } else {
      AppHelpers.showSnackBar(
        context,
        auth.errorMessage ?? 'Could not resend the email.',
        isError: true,
      );
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final busy = auth.isLoading;
    final email = auth.user?.email ?? 'your email address';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        actions: <Widget>[
          TextButton(
            onPressed: busy ? null : () => auth.signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 48,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'One last step',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to $email. Open the link, '
                    'then come back and tap the button below.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (auth.errorMessage != null) ...<Widget>[
                    MessageBanner(
                      message: auth.errorMessage!,
                      icon: Icons.info_outline_rounded,
                      isError: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: busy ? null : _checkVerification,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text("I've verified my email"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: busy || _cooldown > 0 ? null : _resend,
                    child: Text(
                      _cooldown > 0
                          ? 'Resend email in ${_cooldown}s'
                          : 'Resend verification email',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'The link can take a minute to arrive. Check your spam '
                    'folder if you do not see it.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
