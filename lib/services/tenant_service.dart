import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import 'data_errors.dart';

/// A safe, user-facing tenant data failure.
class TenantFailure implements Exception {
  const TenantFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class TenantService {
  TenantService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppUser>> watchTenants() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'tenant')
        .snapshots()
        .map((snapshot) {
          final tenants = snapshot.docs
              .map((doc) => AppUser.fromMap(doc.id, doc.data()))
              .toList();
          tenants.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return tenants;
        });
  }

  Future<AppUser?> fetchTenant(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final tenant = AppUser.fromMap(uid, data);
      return tenant.isTenant ? tenant : null;
    } catch (error) {
      throw TenantFailure(friendlyDataMessage(error));
    }
  }
}
