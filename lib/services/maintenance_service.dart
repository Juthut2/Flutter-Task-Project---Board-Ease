import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/maintenance_request.dart';
import 'data_errors.dart';

/// A safe, user-facing maintenance data failure.
class MaintenanceFailure implements Exception {
  const MaintenanceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class MaintenanceService {
  MaintenanceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.maintenanceCollection);

  Stream<List<MaintenanceRequest>> watchAll() {
    return _requests.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => MaintenanceRequest.fromMap(doc.id, doc.data()))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<MaintenanceRequest>> watchTenantRequests(String tenantId) {
    return _requests.where('tenantId', isEqualTo: tenantId).snapshots().map((
      snapshot,
    ) {
      final requests = snapshot.docs
          .map((doc) => MaintenanceRequest.fromMap(doc.id, doc.data()))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<void> createRequest({
    required String roomId,
    required String tenantId,
    required String title,
    required String description,
    String? photoUrl,
  }) async {
    if (roomId.isEmpty || tenantId.isEmpty) {
      throw const MaintenanceFailure(
        'Your active rental could not be identified.',
      );
    }
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanTitle.isEmpty || cleanDescription.isEmpty) {
      throw const MaintenanceFailure('Add a title and description.');
    }
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('https://res.cloudinary.com/')) {
      throw const MaintenanceFailure('Upload a valid photo first.');
    }
    try {
      await _requests.add(
        MaintenanceRequest(
          roomId: roomId,
          tenantId: tenantId,
          title: cleanTitle,
          description: cleanDescription,
          photoUrl: photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
          status: MaintenanceStatus.pending,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    } catch (error) {
      throw MaintenanceFailure(friendlyDataMessage(error));
    }
  }

  Future<void> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
  }) async {
    if (requestId.isEmpty) {
      throw const MaintenanceFailure('This request could not be identified.');
    }
    try {
      await _requests.doc(requestId).update(<String, dynamic>{
        'status': status.value,
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const MaintenanceFailure(
          'This request could not be updated. Refresh and try again.',
        );
      }
      throw MaintenanceFailure(friendlyDataMessage(error));
    } catch (error) {
      throw MaintenanceFailure(friendlyDataMessage(error));
    }
  }
}
