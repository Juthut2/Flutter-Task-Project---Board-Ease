import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Resets the inactivity timer on interaction, checks timeouts on resume, and
/// clears pushed routes whenever the authentication state changes.
class SessionGuard extends StatefulWidget {
  const SessionGuard({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  late final AuthProvider _auth;
  AuthStatus _lastStatus = AuthStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = context.read<AuthProvider>();
    _lastStatus = _auth.status;
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAuthChanged() {
    final status = _auth.status;
    if (status == _lastStatus) return;
    _lastStatus = status;
    if (status == AuthStatus.unknown) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_auth.checkSessionTimeout());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _auth.recordActivity(),
      child: widget.child,
    );
  }
}
