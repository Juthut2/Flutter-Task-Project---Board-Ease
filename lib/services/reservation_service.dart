import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'data_errors.dart';

/// A safe, user-facing reservation data failure.
class ReservationFailure implements Exception {
  const ReservationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReservationService {
  ReservationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Reservation>> watchAll() {
    return _firestore
        .collection(AppConstants.reservationsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Approves or declines a pending request. Approval marks the room occupied
  /// inside the same transaction so two tenants cannot book it.
  Future<void> decide({
    required String reservationId,
    required bool approve,
  }) async {
    if (reservationId.isEmpty) {
      throw const ReservationFailure('This request could not be identified.');
    }
    try {
      await _firestore.runTransaction((transaction) async {
        final reservationRef = _firestore
            .collection(AppConstants.reservationsCollection)
            .doc(reservationId);
        final reservationSnapshot = await transaction.get(reservationRef);
        if (!reservationSnapshot.exists) {
          throw const ReservationFailure(
            'This reservation no longer exists. Refresh the list.',
          );
        }
        final reservation = Reservation.fromMap(
          reservationSnapshot.id,
          reservationSnapshot.data()!,
        );
        if (reservation.status != ReservationStatus.pending) {
          throw const ReservationFailure(
            'This request was already handled. Refresh the list.',
          );
        }

        final roomRef = _firestore
            .collection(AppConstants.roomsCollection)
            .doc(reservation.roomId);
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists) {
          throw const ReservationFailure(
            'The room for this request no longer exists.',
          );
        }
        final room = Room.fromMap(roomSnapshot.id, roomSnapshot.data()!);

        if (!approve) {
          transaction.update(reservationRef, <String, dynamic>{
            'status': ReservationStatus.declined.value,
          });
          return;
        }

        if (!room.isAvailable) {
          throw const ReservationFailure(
            'This room is no longer available. Decline the request instead.',
          );
        }
        transaction.update(reservationRef, <String, dynamic>{
          'status': ReservationStatus.approved.value,
        });
        transaction.update(roomRef, <String, dynamic>{
          'status': RoomStatus.occupied.value,
          'tenantId': reservation.tenantId,
        });
      });
    } on ReservationFailure {
      rethrow;
    } catch (error) {
      throw ReservationFailure(friendlyDataMessage(error));
    }
  }
}
