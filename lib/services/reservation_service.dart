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

  /// Live reservations that belong to one tenant, newest first.
  Stream<List<Reservation>> watchTenantReservations(String tenantId) {
    return _firestore
        .collection(AppConstants.reservationsCollection)
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) {
          final reservations = snapshot.docs
              .map((doc) => Reservation.fromMap(doc.id, doc.data()))
              .toList();
          reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reservations;
        });
  }

  /// Creates a pending reservation after checking the requested move-in date.
  Future<void> createReservation({
    required String roomId,
    required String tenantId,
    required DateTime moveInDate,
  }) async {
    if (roomId.isEmpty || tenantId.isEmpty) {
      throw const ReservationFailure('This request could not be prepared.');
    }
    final today = DateTime.now();
    final date = DateTime(moveInDate.year, moveInDate.month, moveInDate.day);
    final earliest = DateTime(today.year, today.month, today.day);
    if (date.isBefore(earliest)) {
      throw const ReservationFailure(
        'Choose a move-in date from today onward.',
      );
    }
    try {
      await _firestore
          .collection(AppConstants.reservationsCollection)
          .add(
            Reservation(
              roomId: roomId,
              tenantId: tenantId,
              status: ReservationStatus.pending,
              moveInDate: date,
              createdAt: DateTime.now(),
            ).toMap(),
          );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ReservationFailure(
          'This room is no longer available for reservation. Browse other '
          'rooms or refresh the list.',
        );
      }
      throw ReservationFailure(friendlyDataMessage(error));
    } catch (error) {
      throw ReservationFailure(friendlyDataMessage(error));
    }
  }

  /// Cancels a pending request owned by the signed-in tenant.
  Future<void> cancelReservation(String reservationId) async {
    if (reservationId.isEmpty) {
      throw const ReservationFailure('This request could not be identified.');
    }
    try {
      await _firestore
          .collection(AppConstants.reservationsCollection)
          .doc(reservationId)
          .update(<String, dynamic>{
            'status': ReservationStatus.cancelled.value,
          });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ReservationFailure(
          'This request can no longer be cancelled. Refresh the list.',
        );
      }
      throw ReservationFailure(friendlyDataMessage(error));
    } catch (error) {
      throw ReservationFailure(friendlyDataMessage(error));
    }
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
