import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/data_errors.dart';
import '../services/tenant_service.dart';

/// Live tenant directory available to the property owner.
class TenantsProvider extends ChangeNotifier {
  TenantsProvider({TenantService? service})
    : _service = service ?? TenantService();

  final TenantService _service;

  StreamSubscription<List<AppUser>>? _subscription;
  List<AppUser> _tenants = const <AppUser>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  List<AppUser> get tenants => _tenants;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void watchTenants({bool force = false}) {
    if (!force && _subscription != null) return;
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    _subscription = _service.watchTenants().listen(
      (items) {
        _tenants = items;
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

  void retry() => watchTenants(force: true);

  AppUser? tenantById(String uid) {
    for (final tenant in _tenants) {
      if (tenant.uid == uid) return tenant;
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
