import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/helpers.dart';

enum UserRole {
  owner('owner'),
  tenant('tenant');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    return value == UserRole.owner.value ? UserRole.owner : UserRole.tenant;
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime createdAt;

  bool get isOwner => role == UserRole.owner;

  bool get isTenant => role == UserRole.tenant;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      role: UserRole.fromValue(map['role'] as String?),
      createdAt: AppHelpers.parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
