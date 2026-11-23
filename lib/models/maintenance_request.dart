import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/helpers.dart';

enum MaintenanceStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved');

  const MaintenanceStatus(this.value, this.label);

  final String value;
  final String label;

  static MaintenanceStatus fromValue(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => MaintenanceStatus.pending,
    );
  }
}

class MaintenanceRequest {
  const MaintenanceRequest({
    this.id = '',
    required this.roomId,
    required this.tenantId,
    required this.title,
    required this.description,
    this.photoUrl,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String tenantId;
  final String title;
  final String description;
  final String? photoUrl;
  final MaintenanceStatus status;
  final DateTime createdAt;

  factory MaintenanceRequest.fromMap(String id, Map<String, dynamic> map) {
    final photo = (map['photoUrl'] as String?)?.trim();
    return MaintenanceRequest(
      id: id,
      roomId: (map['roomId'] as String?)?.trim() ?? '',
      tenantId: (map['tenantId'] as String?)?.trim() ?? '',
      title: (map['title'] as String?)?.trim() ?? '',
      description: (map['description'] as String?)?.trim() ?? '',
      photoUrl: photo == null || photo.isEmpty ? null : photo,
      status: MaintenanceStatus.fromValue(map['status'] as String?),
      createdAt: AppHelpers.parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'roomId': roomId,
      'tenantId': tenantId,
      'title': title.trim(),
      'description': description.trim(),
      'photoUrl': photoUrl,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MaintenanceRequest copyWith({
    String? id,
    String? roomId,
    String? tenantId,
    String? title,
    String? description,
    String? photoUrl,
    bool clearPhoto = false,
    MaintenanceStatus? status,
    DateTime? createdAt,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
