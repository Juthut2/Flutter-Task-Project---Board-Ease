import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/tenant_rental.dart';
import '../models/reservation.dart';
import '../services/data_errors.dart';
import '../services/reservation_service.dart';

/// Live reservation requests for the signed-in tenant.
class TenantReservationsProvider extends ChangeNotifier {
  TenantReservationsProvider({ReservationService? service})
    : _service = service ?? ReservationService();

  final ReservationService _service;

  StreamSubscription<List<Reservation>>? _subscription;
  List<Reservation> _reservations = const <Reservation>[];
  bool _isLoading = true;
  String? _errorMessage;
  String? _tenantId;
  bool _disposed = false;

  List<Reservation> get reservations => _reservations;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void watchMine(String tenantId, {bool force = false}) {
    if (!force && _tenantId == tenantId && _subscription != null) return;
    _tenantId = tenantId;
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    _subscription = _service
        .watchTenantReservations(tenantId)
        .listen(
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

  void retry() {
    final tenantId = _tenantId;
    if (tenantId == null) return;
    watchMine(tenantId, force: true);
  }

  Future<void> create({required String roomId, required DateTime moveInDate}) {
    final tenantId = _tenantId;
    if (tenantId == null) {
      throw const ReservationFailure('Sign in again to reserve a room.');
    }
    return _service.createReservation(
      roomId: roomId,
      tenantId: tenantId,
      moveInDate: moveInDate,
    );
  }

  Future<void> cancel(Reservation reservation) {
    return _service.cancelReservation(reservation.id);
  }

  Reservation? blockingForRoom(String roomId) {
    return TenantRentalSummary.blockingReservation(_reservations, roomId);
  }

  List<Reservation> get activeRequests => _reservations
      .where(
        (item) =>
            item.status == ReservationStatus.pending ||
            item.status == ReservationStatus.approved,
      )
      .toList();

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
