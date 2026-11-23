import 'package:firebase_auth/firebase_auth.dart';

bool isCredentialFailure(String code) {
  return code == 'wrong-password' ||
      code == 'user-not-found' ||
      code == 'invalid-credential';
}

/// Converts Firebase Auth error codes into safe, friendly messages.
String friendlyAuthMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact the owner.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'weak-password':
      return 'Choose a stronger password with letters and numbers.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'requires-recent-login':
      return 'Please sign in again to continue.';
    default:
      return 'Authentication failed. Please try again.';
  }
}
