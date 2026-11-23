// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import 'session_service.dart';

/// Resets the inactivity countdown on interaction and persists activity.
class InactivityGuard {
  InactivityGuard({
    required SessionService session,
    required VoidCallback onTimeout,
  }) : _session = session,
       _onTimeout = onTimeout;

  final SessionService _session;
  final VoidCallback _onTimeout;

  Timer? _timer;
  DateTime? _lastSaved;

  void start() {
    _timer?.cancel();
    _timer = Timer(AppConstants.inactivityTimeout, _onTimeout);
  }

  void recordActivity() {
    start();
    final now = DateTime.now();
    final previous = _lastSaved;
    if (previous == null ||
        now.difference(previous) >= const Duration(seconds: 20)) {
      _lastSaved = now;
      unawaited(_session.touch(now));
    }
  }

  Future<void> checkOnResume() async {
    final lastActive = await _session.lastActive();
    if (lastActive != null &&
        DateTime.now().difference(lastActive) >=
            AppConstants.inactivityTimeout) {
      _onTimeout();
    } else {
      start();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
