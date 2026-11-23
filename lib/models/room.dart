import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/helpers.dart';

enum RoomStatus {
  available('available', 'Available'),
  reserved('reserved', 'Reserved'),
  occupied('occupied', 'Occupied');

  const RoomStatus(this.value, this.label);

  final String value;
  final String label;

  static RoomStatus fromValue(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => RoomStatus.available,
    );
  }
}

class Room {
  const Room({
    this.id = '',
    required this.ownerId,
    required this.name,
    this.description = '',
    required this.monthlyRate,
    required this.deposit,
    required this.capacity,
    this.amenities = const <String>[],
    this.rules = '',
    this.photos = const <String>[],
    required this.status,
    this.province = '',
    this.city = '',
    this.barangay = '',
    this.street = '',
    this.tenantId,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final double monthlyRate;
  final double deposit;
  final int capacity;
  final List<String> amenities;
  final String rules;
  final List<String> photos;
  final RoomStatus status;
  final String province;
  final String city;
  final String barangay;
  final String street;
  final String? tenantId;
  final DateTime createdAt;

  bool get isAvailable => status == RoomStatus.available;

  String get coverPhoto => photos.isEmpty ? '' : photos.first;

  String get fullAddress {
    final parts = <String>[
      street,
      barangay,
      city,
      province,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    return Room(
      id: id,
      ownerId: (map['ownerId'] as String?)?.trim() ?? '',
      name: (map['name'] as String?)?.trim() ?? '',
      description: (map['description'] as String?)?.trim() ?? '',
      monthlyRate: (map['monthlyRate'] as num?)?.toDouble() ?? 0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0,
      capacity: (map['capacity'] as num?)?.toInt() ?? 1,
      amenities: _stringList(map['amenities']),
      rules: (map['rules'] as String?)?.trim() ?? '',
      photos: _stringList(map['photos']),
      status: RoomStatus.fromValue(map['status'] as String?),
      province: (map['province'] as String?)?.trim() ?? '',
      city: (map['city'] as String?)?.trim() ?? '',
      barangay: (map['barangay'] as String?)?.trim() ?? '',
      street: (map['street'] as String?)?.trim() ?? '',
      tenantId: (map['tenantId'] as String?)?.trim(),
      createdAt: AppHelpers.parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'name': name.trim(),
      'description': description.trim(),
      'monthlyRate': monthlyRate,
      'deposit': deposit,
      'capacity': capacity,
      'amenities': amenities,
      'rules': rules.trim(),
      'photos': photos,
      'status': status.value,
      'province': province.trim(),
      'city': city.trim(),
      'barangay': barangay.trim(),
      'street': street.trim(),
      'tenantId': tenantId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Room copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    double? monthlyRate,
    double? deposit,
    int? capacity,
    List<String>? amenities,
    String? rules,
    List<String>? photos,
    RoomStatus? status,
    String? province,
    String? city,
    String? barangay,
    String? street,
    String? tenantId,
    bool clearTenant = false,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyRate: monthlyRate ?? this.monthlyRate,
      deposit: deposit ?? this.deposit,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      rules: rules ?? this.rules,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      province: province ?? this.province,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      street: street ?? this.street,
      tenantId: clearTenant ? null : (tenantId ?? this.tenantId),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
