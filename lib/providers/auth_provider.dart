import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../services/auth_errors.dart';
import '../services/auth_service.dart';
import '../services/inactivity_guard.dart';
import '../services/login_lockout.dart';
import '../services/session_service.dart';

part 'auth_recovery.dart';

enum AuthStatus { unknown, unauthenticated, unverified, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, SessionService? sessionService})
    // ignore: prefer_initializing_formals
    : _authService = authService,
      _session = sessionService ?? SessionService() {
    _lockout = LoginLockout(session: _session, onChanged: _safeNotify);
    _inactivity = InactivityGuard(
      session: _session,
      onTimeout: () => unawaited(
        signOut(message: 'You were signed out after 15 minutes of inactivity.'),
      ),
    );
  }

  final SessionService _session;
  AuthService? _authService;
  late final LoginLockout _lockout;
  late final InactivityGuard _inactivity;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _isLoading = false;
  bool _disposed = false;
  String? _errorMessage;

  AuthStatus get status => _status;

  AppUser? get user => _user;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get failedAttempts => _lockout.failedAttempts;

  bool get isLockedOut => _lockout.isLockedOut;

  int get lockoutSecondsRemaining => _lockout.secondsRemaining;

  Future<void> initialize() async {
    await _lockout.restore();
    try {
      final service = _authService ??= AuthService();
      final current = service.currentUser;
      if (current == null) {
        _status = AuthStatus.unauthenticated;
        _safeNotify();
        return;
      }

      final lastActive = await _session.lastActive();
      if (lastActive != null &&
          DateTime.now().difference(lastActive) >=
              AppConstants.inactivityTimeout) {
        await service.signOut();
        await _session.clearSession();
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Your session expired. Please sign in again.';
        _safeNotify();
        return;
      }

      await _completeSession(current);
    } on AuthFailure catch (error) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = error.message;
      _safeNotify();
    } catch (_) {
      // Keep the splash visible when Firebase is not available (widget tests).
      var firebaseReady = false;
      try {
        firebaseReady = Firebase.apps.isNotEmpty;
      } catch (_) {
        firebaseReady = false;
      }
      _status = firebaseReady ? AuthStatus.unauthenticated : AuthStatus.unknown;
      if (firebaseReady) {
        _errorMessage = 'Could not restore your session. Please sign in again.';
      }
      _safeNotify();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_lockout.isLockedOut) {
      _errorMessage =
          'Too many failed attempts. Try again in '
          '${_lockout.secondsRemaining}s.';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService ??= AuthService();
      final credential = await service.signIn(email: email, password: password);
      final authUser = credential.user;
      if (authUser == null) {
        throw const AuthFailure('Could not sign in. Please try again.');
      }
      await _completeSession(authUser);
      await _lockout.reset();
      return true;
    } on FirebaseAuthException catch (error) {
      if (isCredentialFailure(error.code)) {
        await _lockout.recordFailure();
      }
      _errorMessage = friendlyAuthMessage(error);
      return false;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not sign in right now. Check your connection and try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService ??= AuthService();
      final credential = await service.signInWithGoogle();
      final authUser = credential.user;
      if (authUser == null) {
        throw const AuthFailure('Could not sign in. Please try again.');
      }

      final existing = await service.fetchProfile(authUser.uid);
      if (existing == null) {
        final email = authUser.email?.trim() ?? '';
        final displayName = authUser.displayName?.trim() ?? '';
        final fallbackName = email.contains('@')
            ? email.split('@').first.trim()
            : '';
        final name = displayName.isNotEmpty
            ? displayName
            : (fallbackName.isNotEmpty ? fallbackName : 'Tenant');
        await service.createGoogleTenantProfile(
          uid: authUser.uid,
          name: name,
          email: email,
          photoUrl: authUser.photoURL,
        );
      }

      await _completeSession(authUser, assumeVerified: true);
      await _lockout.reset();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = friendlyAuthMessage(error);
      return false;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not sign in with Google. Check your connection and try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> registerTenant({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gender,
    required DateTime birthday,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService ??= AuthService();
      final credential = await service.registerTenant(
        name: name,
        email: email,
        phone: phone,
        password: password,
        gender: gender,
        birthday: birthday,
      );
      final authUser = credential.user;
      if (authUser == null) {
        throw const AuthFailure('Could not create your account. Try again.');
      }
      await _completeSession(authUser);
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = friendlyAuthMessage(error);
      return false;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not create your account. Check your connection and try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String gender,
    required DateTime birthday,
  }) async {
    final current = _user;
    if (current == null) {
      _errorMessage = 'You are not signed in.';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService ??= AuthService();
      await service.updateProfile(
        uid: current.uid,
        name: name,
        phone: phone,
        gender: gender,
        birthday: birthday,
      );
      _user = current.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        gender: gender,
        birthday: birthday,
      );
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not update your profile. Check your connection and try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> updatePhotoUrl(String photoUrl) async {
    final current = _user;
    if (current == null) {
      _errorMessage = 'You are not signed in.';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService ??= AuthService();
      await service.updatePhotoUrl(uid: current.uid, photoUrl: photoUrl);
      _user = current.copyWith(photoUrl: photoUrl);
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not save your photo. Check your connection and try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> signOut({String? message}) async {
    _inactivity.stop();
    try {
      await _authService?.signOut();
    } catch (_) {
      // Local state is cleared regardless of the network result.
    }
    await _session.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    _errorMessage = message;
    _safeNotify();
  }

  /// Resets the inactivity timer and persists activity at most every 20s.
  void recordActivity() {
    if (_status != AuthStatus.authenticated &&
        _status != AuthStatus.unverified) {
      return;
    }
    _inactivity.recordActivity();
  }

  /// Called when the app returns to the foreground.
  Future<void> checkSessionTimeout() async {
    if (_status != AuthStatus.authenticated &&
        _status != AuthStatus.unverified) {
      return;
    }
    await _inactivity.checkOnResume();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  Future<void> _completeSession(
    User authUser, {
    bool assumeVerified = false,
  }) async {
    final service = _authService;
    if (service == null) {
      throw const AuthFailure('Authentication is unavailable.');
    }

    AppUser? profile;
    try {
      profile = await service.fetchProfile(authUser.uid);
    } catch (_) {
      await service.signOut();
      await _session.clearSession();
      throw const AuthFailure(
        'Could not load your account. Check your connection and try again.',
      );
    }
    if (profile == null) {
      await service.signOut();
      await _session.clearSession();
      throw const AuthFailure(
        'No account profile was found. Please contact the property owner.',
      );
    }

    _user = profile;
    _status = assumeVerified || authUser.emailVerified
        ? AuthStatus.authenticated
        : AuthStatus.unverified;
    _errorMessage = null;
    await _session.saveSession(authUser.uid);
    _inactivity.start();
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _lockout.dispose();
    _inactivity.dispose();
    super.dispose();
  }
}
