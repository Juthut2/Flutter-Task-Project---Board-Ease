import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/room.dart';
import 'data_errors.dart';

/// A safe, user-facing room data failure.
class RoomFailure implements Exception {
  const RoomFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class RoomService {
  RoomService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection(AppConstants.roomsCollection);

  Stream<List<Room>> watchOwnerRooms(String ownerId) {
    return _rooms.where('ownerId', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final rooms = snapshot.docs
          .map((doc) => Room.fromMap(doc.id, doc.data()))
          .toList();
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rooms;
    });
  }

  /// Live room directory for tenants, including occupied rooms so an active
  /// rental can still be displayed after its room leaves the browse list.
  Stream<List<Room>> watchAllRooms() {
    return _rooms.snapshots().map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => Room.fromMap(doc.id, doc.data()))
          .toList();
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rooms;
    });
  }

  Future<void> createRoom(Room room) async {
    try {
      await _rooms.add(room.toMap());
    } catch (error) {
      throw RoomFailure(friendlyDataMessage(error));
    }
  }

  Future<void> updateRoom(Room room) async {
    if (room.id.isEmpty) {
      throw const RoomFailure('This room could not be identified.');
    }
    try {
      await _rooms.doc(room.id).update(room.toMap());
    } catch (error) {
      throw RoomFailure(friendlyDataMessage(error));
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (roomId.isEmpty) {
      throw const RoomFailure('This room could not be identified.');
    }
    try {
      await _rooms.doc(roomId).delete();
    } catch (error) {
      throw RoomFailure(friendlyDataMessage(error));
    }
  }
}
