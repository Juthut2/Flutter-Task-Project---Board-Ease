import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/maintenance_request.dart';
import '../services/data_errors.dart';
import '../services/maintenance_service.dart';

/// Live maintenance requests for the owner's rooms.
class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({MaintenanceService? service})
    : _service = service ?? MaintenanceService();

  final MaintenanceService _service;

  StreamSubscription<List<MaintenanceRequest>>? _subscription;
  List<MaintenanceRequest> _requests = const <MaintenanceRequest>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  List<MaintenanceRequest> get requests => _requests;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get pendingCount => _requests
      .where((item) => item.status == MaintenanceStatus.pending)
      .length;

  int pendingCountFor(Set<String> roomIds) => _requests
      .where(
        (item) =>
            item.status == MaintenanceStatus.pending &&
            roomIds.contains(item.roomId),
      )
      .length;

  void watchAll({bool force = false}) {
    if (!force && _subscription != null) return;
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    _subscription = _service.watchAll().listen(
      (items) {
        _requests = items;
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

  Future<void> updateStatus(
    MaintenanceRequest request,
    MaintenanceStatus status,
  ) {
    return _service.updateStatus(requestId: request.id, status: status);
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
