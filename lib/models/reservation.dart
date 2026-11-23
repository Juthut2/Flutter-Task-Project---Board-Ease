import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/helpers.dart';

enum ReservationStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  declined('declined', 'Declined'),
  cancelled('cancelled', 'Cancelled');

  const ReservationStatus(this.value, this.label);

  final String value;
  final String label;

  static ReservationStatus fromValue(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

class Reservation {
  const Reservation({
    this.id = '',
    required this.roomId,
    required this.tenantId,
    required this.status,
    required this.moveInDate,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String tenantId;
  final ReservationStatus status;
  final DateTime moveInDate;
  final DateTime createdAt;

  bool get isPending => status == ReservationStatus.pending;

  factory Reservation.fromMap(String id, Map<String, dynamic> map) {
    return Reservation(
      id: id,
      roomId: (map['roomId'] as String?)?.trim() ?? '',
      tenantId: (map['tenantId'] as String?)?.trim() ?? '',
      status: ReservationStatus.fromValue(map['status'] as String?),
      moveInDate: AppHelpers.parseDate(map['moveInDate']) ?? DateTime.now(),
      createdAt: AppHelpers.parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'roomId': roomId,
      'tenantId': tenantId,
      'status': status.value,
      'moveInDate': Timestamp.fromDate(moveInDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Reservation copyWith({
    String? id,
    String? roomId,
    String? tenantId,
    ReservationStatus? status,
    DateTime? moveInDate,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      moveInDate: moveInDate ?? this.moveInDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
