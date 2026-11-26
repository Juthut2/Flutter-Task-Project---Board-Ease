import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../services/data_errors.dart';
import '../services/payment_service.dart';

/// Live payment history and submission state for the signed-in tenant.
class TenantPaymentsProvider extends ChangeNotifier {
  TenantPaymentsProvider({PaymentService? service})
    : _service = service ?? PaymentService();

  final PaymentService _service;

  StreamSubscription<List<Payment>>? _subscription;
  List<Payment> _payments = const <Payment>[];
  bool _isLoading = true;
  String? _errorMessage;
  String? _tenantId;
  bool _disposed = false;

  List<Payment> get payments => _payments;

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
        .watchTenantPayments(tenantId)
        .listen(
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

  void retry() {
    final tenantId = _tenantId;
    if (tenantId == null) return;
    watchMine(tenantId, force: true);
  }

  Future<void> submit({
    required String roomId,
    required double amount,
    required String month,
    required String proofUrl,
  }) {
    final tenantId = _tenantId;
    if (tenantId == null) {
      throw const PaymentFailure('Sign in again to submit a payment.');
    }
    return _service.submitPayment(
      Payment(
        roomId: roomId,
        tenantId: tenantId,
        amount: amount,
        month: month,
        proofUrl: proofUrl,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
  }

  List<Payment> forRoom(String roomId) {
    return _payments.where((payment) => payment.roomId == roomId).toList();
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
