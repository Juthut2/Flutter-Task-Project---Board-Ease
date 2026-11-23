part of 'auth_provider.dart';

/// Password reset and email verification actions for [AuthProvider].
extension AuthRecovery on AuthProvider {
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService ??= AuthService();
      await service.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = friendlyAuthMessage(error);
      return false;
    } catch (_) {
      _errorMessage =
          'Could not send the reset link. Check your connection and try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> resendVerificationEmail() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final service = _authService;
      if (service == null) {
        throw const AuthFailure('You are not signed in.');
      }
      await service.sendVerificationEmail();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = friendlyAuthMessage(error);
      return false;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not resend the verification email. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> refreshEmailVerification() async {
    final service = _authService;
    if (service == null) {
      _errorMessage = 'You are not signed in.';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final refreshed = await service.reloadCurrentUser();
      if (refreshed == null) {
        throw const AuthFailure('You are not signed in.');
      }
      if (!refreshed.emailVerified) {
        _errorMessage =
            'Your email is not verified yet. Open the link in your inbox, '
            'then try again.';
        return false;
      }
      await _completeSession(refreshed);
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Could not check verification right now. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }
}
