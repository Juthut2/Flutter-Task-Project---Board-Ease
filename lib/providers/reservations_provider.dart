import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/reservation.dart';
import '../models/room.dart';
import '../services/data_errors.dart';
import '../services/reservation_service.dart';

/// Owns live reservation requests and the owner approval workflow.
class ReservationsProvider extends ChangeNotifier {
  ReservationsProvider({ReservationService? service})
    : _service = service ?? ReservationService();

  final ReservationService _service;

  StreamSubscription<List<Reservation>>? _subscription;
  List<Reservation> _reservations = const <Reservation>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  List<Reservation> get reservations => _reservations;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void watchAll({bool force = false}) {
    if (!force && _subscription != null) return;
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    _subscription = _service.watchAll().listen(
      (items) {
        _reservations = items;
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

  List<Reservation> forRooms(List<Room> rooms) {
    final roomIds = rooms.map((room) => room.id).toSet();
    return _reservations
        .where((item) => roomIds.contains(item.roomId))
        .toList();
  }

  int pendingCount(List<Room> rooms) {
    return forRooms(rooms)
        .where((item) => item.status == ReservationStatus.pending)
        .length;
  }

  Future<void> decide(Reservation reservation, {required bool approve}) {
    return _service.decide(reservationId: reservation.id, approve: approve);
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
