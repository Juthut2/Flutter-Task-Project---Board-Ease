import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../owner/owner_shell.dart';
import '../tenant/tenant_shell.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'verify_email_screen.dart';

/// Routes based on the authenticated user's status and Firestore role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unverified:
        return const VerifyEmailScreen();
      case AuthStatus.authenticated:
        final user = auth.user;
        if (user == null) return const LoginScreen();
        return user.isOwner ? const OwnerShell() : const TenantShell();
    }
  }
}
