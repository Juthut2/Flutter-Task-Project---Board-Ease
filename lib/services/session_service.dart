import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted login attempt state used by the lockout helper.
class LoginAttemptState {
  const LoginAttemptState({this.failedAttempts = 0, this.lockoutUntil});

  final int failedAttempts;
  final DateTime? lockoutUntil;
}

/// All locally stored session data goes through encrypted secure storage.
class SessionService {
  SessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _uidKey = 'boardease_session_uid';
  static const String _lastActiveKey = 'boardease_session_last_active';
  static const String _attemptsKey = 'boardease_login_attempts';
  static const String _lockoutKey = 'boardease_login_lockout_until';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(String uid) async {
    try {
      await _storage.write(key: _uidKey, value: uid);
      await touch(DateTime.now());
    } catch (_) {
      // A session still works for this run if secure storage is unavailable.
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _uidKey);
      await _storage.delete(key: _lastActiveKey);
    } catch (_) {
      // Ignore storage failures.
    }
  }

  Future<void> touch(DateTime value) async {
    try {
      await _storage.write(key: _lastActiveKey, value: value.toIso8601String());
    } catch (_) {
      // Ignore storage failures.
    }
  }

  Future<DateTime?> lastActive() async {
    try {
      final value = await _storage.read(key: _lastActiveKey);
      return DateTime.tryParse(value ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<LoginAttemptState> loadLoginAttempts() async {
    try {
      final attemptsValue = await _storage.read(key: _attemptsKey);
      final lockoutValue = await _storage.read(key: _lockoutKey);
      return LoginAttemptState(
        failedAttempts: int.tryParse(attemptsValue ?? '') ?? 0,
        lockoutUntil: DateTime.tryParse(lockoutValue ?? ''),
      );
    } catch (_) {
      return const LoginAttemptState();
    }
  }

  Future<void> saveLoginAttempts({
    required int failedAttempts,
    DateTime? lockoutUntil,
  }) async {
    try {
      await _storage.write(key: _attemptsKey, value: '$failedAttempts');
      if (lockoutUntil != null) {
        await _storage.write(
          key: _lockoutKey,
          value: lockoutUntil.toIso8601String(),
        );
      } else {
        await _storage.delete(key: _lockoutKey);
      }
    } catch (_) {
      // The lockout still applies in-memory even if persistence fails.
    }
  }

  Future<void> clearLoginAttempts() async {
    try {
      await _storage.delete(key: _attemptsKey);
      await _storage.delete(key: _lockoutKey);
    } catch (_) {
      // Ignore storage failures.
    }
  }
}
