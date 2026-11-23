import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/payment.dart';

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
}
