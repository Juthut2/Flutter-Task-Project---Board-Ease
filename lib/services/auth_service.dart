import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

/// A user-facing authentication failure that is safe to display.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static Future<void>? _googleInitialization;

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    final existing = _googleInitialization;
    if (existing != null) return existing;
    final future = GoogleSignIn.instance.initialize(
      serverClientId: AppConstants.googleServerClientId.isEmpty
          ? null
          : AppConstants.googleServerClientId,
    );
    _googleInitialization = future;
    try {
      await future;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    try {
      await _ensureGoogleInitialized();
    } on GoogleSignInException catch (error) {
      throw _googleFailure(error);
    } catch (_) {
      throw const AuthFailure(
        'Google sign-in is not available right now. Please try again.',
      );
    }

    if (!google.supportsAuthenticate()) {
      throw const AuthFailure(
        'Google sign-in is not supported on this device.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (error) {
      throw _googleFailure(error);
    } catch (_) {
      throw const AuthFailure('Google sign-in failed. Please try again.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure(
        'Google sign-in did not return a valid credential. Please try again.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  AuthFailure _googleFailure(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return const AuthFailure('Google sign-in was cancelled.');
      case GoogleSignInExceptionCode.clientConfigurationError:
        return const AuthFailure(
          'Google sign-in is not configured for this app. '
          'Please contact the property owner.',
        );
      default:
        return const AuthFailure('Google sign-in failed. Please try again.');
    }
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap(uid, data);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a tenant. The client never creates owner accounts.
  Future<UserCredential> registerTenant({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gender,
    required DateTime birthday,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure(
        'Could not create your account. Please try again.',
      );
    }

    try {
      await user.updateDisplayName(name.trim());
      final profile = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.tenant,
        createdAt: DateTime.now(),
        gender: gender,
        birthday: birthday,
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(profile.toMap());

      // Verification is attempted at registration; the verify screen can resend.
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // The account exists and the user can resend from the verify screen.
      }
      return credential;
    } catch (error) {
      try {
        await user.delete();
      } catch (_) {
        await _auth.signOut();
      }
      rethrow;
    }
  }

  /// Creates the Firestore profile for a first-time Google sign-in.
  Future<void> createGoogleTenantProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final profile = AppUser(
      uid: uid,
      name: name,
      email: email,
      role: UserRole.tenant,
      createdAt: DateTime.now(),
      photoUrl: photoUrl,
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(profile.toMap());
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String gender,
    required DateTime birthday,
  }) {
    return _firestore.collection(AppConstants.usersCollection).doc(uid).update(
      <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'gender': gender,
        'birthday': Timestamp.fromDate(birthday),
      },
    );
  }

  Future<void> updatePhotoUrl({required String uid, required String photoUrl}) {
    return _firestore.collection(AppConstants.usersCollection).doc(uid).update(
      <String, dynamic>{'photoUrl': photoUrl},
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('You are not signed in.');
    }
    await user.sendEmailVerification();
  }

  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }

  Future<void> signOut() => _auth.signOut();
}
