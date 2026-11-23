import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/room.dart';
import '../services/data_errors.dart';
import '../services/room_service.dart';

/// Owns the signed-in owner's live room list and room write operations.
class RoomsProvider extends ChangeNotifier {
  RoomsProvider({RoomService? service}) : _service = service ?? RoomService();

  final RoomService _service;

  StreamSubscription<List<Room>>? _subscription;
  List<Room> _rooms = const <Room>[];
  bool _isLoading = true;
  String? _errorMessage;
  String? _ownerId;
  bool _disposed = false;

  List<Room> get rooms => _rooms;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void watchOwnerRooms(String ownerId, {bool force = false}) {
    if (!force && _ownerId == ownerId && _subscription != null) return;
    _ownerId = ownerId;
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    _subscription = _service
        .watchOwnerRooms(ownerId)
        .listen(
          (rooms) {
            _rooms = rooms;
            _isLoading = false;
            _errorMessage = null;
            _safeNotify();
          },
          onError: (Object error) {
            _errorMessage = friendlyDataMessage(error);
            _isLoading = false;
            _safeNotify();
          },
          onDone: () {
            _isLoading = false;
            _safeNotify();
          },
        );
  }

  void retry() {
    final ownerId = _ownerId;
    if (ownerId == null) return;
    watchOwnerRooms(ownerId, force: true);
  }

  Future<void> createRoom(Room room) => _service.createRoom(room);

  Future<void> updateRoom(Room room) => _service.updateRoom(room);

  Future<void> deleteRoom(String roomId) => _service.deleteRoom(roomId);

  Room? roomById(String roomId) {
    for (final room in _rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
