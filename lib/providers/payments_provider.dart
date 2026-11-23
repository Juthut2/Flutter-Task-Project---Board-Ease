import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../services/data_errors.dart';
import '../services/payment_service.dart';

/// Live payment records used by the owner dashboard.
class PaymentsProvider extends ChangeNotifier {
  PaymentsProvider({PaymentService? service})
    : _service = service ?? PaymentService();

  final PaymentService _service;

  StreamSubscription<List<Payment>>? _subscription;
  List<Payment> _payments = const <Payment>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  List<Payment> get payments => _payments;

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
        _payments = items;
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
