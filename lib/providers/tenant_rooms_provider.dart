import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/room.dart';
import '../services/data_errors.dart';
import '../services/room_service.dart';

/// Live room directory for the signed-in tenant.
class TenantRoomsProvider extends ChangeNotifier {
  TenantRoomsProvider({RoomService? service})
    : _service = service ?? RoomService();

  final RoomService _service;

  StreamSubscription<List<Room>>? _subscription;
  List<Room> _rooms = const <Room>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  List<Room> get rooms => _rooms;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Rooms a tenant can still request, newest first.
  List<Room> get availableRooms =>
      _rooms.where((room) => room.isAvailable).toList();

  void watchAll({bool force = false}) {
    if (!force && _subscription != null) return;
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    _subscription = _service.watchAllRooms().listen(
      (items) {
        _rooms = items;
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

  void retry() => watchAll(force: true);

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
