// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import 'session_service.dart';

/// Tracks failed sign-in attempts and enforces a temporary lockout.
class LoginLockout {
  LoginLockout({
    required SessionService session,
    required VoidCallback onChanged,
  }) : _session = session,
       _onChanged = onChanged;

  final SessionService _session;
  final VoidCallback _onChanged;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _ticker;
  bool _disposed = false;

  int get failedAttempts => _failedAttempts;

  bool get isLockedOut {
    final until = _lockoutUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  int get secondsRemaining {
    final until = _lockoutUntil;
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining + 1;
  }

  Future<void> restore() async {
    final state = await _session.loadLoginAttempts();
    _failedAttempts = state.failedAttempts;
    final until = state.lockoutUntil;
    if (until != null && until.isAfter(DateTime.now())) {
      _lockoutUntil = until;
      _startTicker();
    } else {
      _lockoutUntil = null;
      if (until != null) {
        _failedAttempts = 0;
        await _session.clearLoginAttempts();
      }
    }
  }

  Future<void> recordFailure() async {
    _failedAttempts += 1;
    if (_failedAttempts >= AppConstants.maxFailedLoginAttempts) {
      _lockoutUntil = DateTime.now().add(AppConstants.loginLockoutDuration);
      _failedAttempts = AppConstants.maxFailedLoginAttempts;
      _startTicker();
    }
    await _session.saveLoginAttempts(
      failedAttempts: _failedAttempts,
      lockoutUntil: _lockoutUntil,
    );
  }

  Future<void> reset() async {
    _failedAttempts = 0;
    _lockoutUntil = null;
    _ticker?.cancel();
    _ticker = null;
    await _session.clearLoginAttempts();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (!isLockedOut) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isLockedOut) {
        timer.cancel();
        _ticker = null;
        _lockoutUntil = null;
        _failedAttempts = 0;
        unawaited(_session.clearLoginAttempts());
      }
      if (!_disposed) _onChanged();
    });
  }

  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _ticker = null;
  }
}
