import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/maintenance_request.dart';
import '../services/data_errors.dart';
import '../services/maintenance_service.dart';

/// Live maintenance requests submitted by the signed-in tenant.
class TenantMaintenanceProvider extends ChangeNotifier {
  TenantMaintenanceProvider({MaintenanceService? service})
    : _service = service ?? MaintenanceService();

  final MaintenanceService _service;

  StreamSubscription<List<MaintenanceRequest>>? _subscription;
  List<MaintenanceRequest> _requests = const <MaintenanceRequest>[];
  bool _isLoading = true;
  String? _errorMessage;
  String? _tenantId;
  bool _disposed = false;

  List<MaintenanceRequest> get requests => _requests;

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
        .watchTenantRequests(tenantId)
        .listen(
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

  void retry() {
    final tenantId = _tenantId;
    if (tenantId == null) return;
    watchMine(tenantId, force: true);
  }

  Future<void> create({
    required String roomId,
    required String title,
    required String description,
    String? photoUrl,
  }) {
    final tenantId = _tenantId;
    if (tenantId == null) {
      throw const MaintenanceFailure(
        'Sign in again to submit a maintenance request.',
      );
    }
    return _service.createRequest(
      roomId: roomId,
      tenantId: tenantId,
      title: title,
      description: description,
      photoUrl: photoUrl,
    );
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
