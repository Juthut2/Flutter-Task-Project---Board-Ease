import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firestore errors into friendly, non-sensitive messages.
String friendlyDataMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'You appear to be offline. Check your connection and retry.';
      case 'not-found':
        return 'That item no longer exists.';
      case 'failed-precondition':
        return 'This action could not be completed. Refresh and try again.';
      case 'deadline-exceeded':
        return 'The request timed out. Please try again.';
      case 'aborted':
        return 'The data changed while saving. Refresh and try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      case 'cancelled':
        return 'The request was cancelled. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
