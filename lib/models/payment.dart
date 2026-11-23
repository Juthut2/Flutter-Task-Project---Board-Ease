import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/helpers.dart';

enum PaymentStatus {
  pending('pending', 'Pending'),
  verified('verified', 'Verified'),
  rejected('rejected', 'Rejected');

  const PaymentStatus(this.value, this.label);

  final String value;
  final String label;

  static PaymentStatus fromValue(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class Payment {
  const Payment({
    this.id = '',
    required this.roomId,
    required this.tenantId,
    required this.amount,
    required this.month,
    required this.proofUrl,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String tenantId;
  final double amount;
  final String month;
  final String proofUrl;
  final PaymentStatus status;
  final DateTime createdAt;

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      roomId: (map['roomId'] as String?)?.trim() ?? '',
      tenantId: (map['tenantId'] as String?)?.trim() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      month: (map['month'] as String?)?.trim() ?? '',
      proofUrl: (map['proofUrl'] as String?)?.trim() ?? '',
      status: PaymentStatus.fromValue(map['status'] as String?),
      createdAt: AppHelpers.parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'roomId': roomId,
      'tenantId': tenantId,
      'amount': amount,
      'month': month.trim(),
      'proofUrl': proofUrl.trim(),
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Payment copyWith({
    String? id,
    String? roomId,
    String? tenantId,
    double? amount,
    String? month,
    String? proofUrl,
    PaymentStatus? status,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      proofUrl: proofUrl ?? this.proofUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
