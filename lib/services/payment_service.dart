import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/payment.dart';
import 'data_errors.dart';

/// A safe, user-facing payment data failure.
class PaymentFailure implements Exception {
  const PaymentFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentService {
  PaymentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Payment>> watchAll() {
    return _firestore
        .collection(AppConstants.paymentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Payment.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Live payment history for one tenant, newest first.
  Stream<List<Payment>> watchTenantPayments(String tenantId) {
    return _firestore
        .collection(AppConstants.paymentsCollection)
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) => Payment.fromMap(doc.id, doc.data()))
              .toList();
          payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return payments;
        });
  }

  /// Submits a pending proof of payment for owner verification.
  Future<void> submitPayment(Payment payment) async {
    if (payment.roomId.isEmpty || payment.tenantId.isEmpty) {
      throw const PaymentFailure('This payment could not be prepared.');
    }
    if (payment.amount <= 0) {
      throw const PaymentFailure('Enter an amount greater than zero.');
    }
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(payment.month)) {
      throw const PaymentFailure('Choose a valid payment month.');
    }
    if (!payment.proofUrl.startsWith('https://res.cloudinary.com/')) {
      throw const PaymentFailure('Upload a proof of payment image first.');
    }
    try {
      await _firestore
          .collection(AppConstants.paymentsCollection)
          .add(payment.toMap());
    } catch (error) {
      throw PaymentFailure(friendlyDataMessage(error));
    }
  }

  /// Verifies or rejects a pending payment in a transaction.
  Future<void> decide({
    required String paymentId,
    required bool approve,
  }) async {
    if (paymentId.isEmpty) {
      throw const PaymentFailure('This payment could not be identified.');
    }
    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _firestore
            .collection(AppConstants.paymentsCollection)
            .doc(paymentId);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) {
          throw const PaymentFailure(
            'This payment no longer exists. Refresh the list.',
          );
        }
        final payment = Payment.fromMap(snapshot.id, snapshot.data()!);
        if (payment.status != PaymentStatus.pending) {
          throw const PaymentFailure(
            'This payment was already reviewed. Refresh the list.',
          );
        }
        transaction.update(reference, <String, dynamic>{
          'status': approve
              ? PaymentStatus.verified.value
              : PaymentStatus.rejected.value,
        });
      });
    } on PaymentFailure {
      rethrow;
    } catch (error) {
      throw PaymentFailure(friendlyDataMessage(error));
    }
  }
}
