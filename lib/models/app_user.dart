import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
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
    this.gender,
    this.birthday,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime createdAt;

  /// One of [AppConstants.genderOptions] keys, or null for older accounts.
  final String? gender;

  /// Stored in Firestore as a [Timestamp].
  final DateTime? birthday;

  final String? photoUrl;

  bool get isOwner => role == UserRole.owner;

  bool get isTenant => role == UserRole.tenant;

  bool get hasCompleteProfile => gender != null && birthday != null;

  String get genderLabel {
    if (gender == null) return 'Not provided';
    return AppConstants.genderOptions[gender] ?? 'Not provided';
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final rawGender = map['gender'] is String ? map['gender'] as String : null;
    final photo = (map['photoUrl'] as String?)?.trim();
    return AppUser(
      uid: uid,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      role: UserRole.fromValue(map['role'] as String?),
      createdAt: AppHelpers.parseDate(map['createdAt']) ?? DateTime.now(),
      gender:
          rawGender != null && AppConstants.genderOptions.containsKey(rawGender)
          ? rawGender
          : null,
      birthday: AppHelpers.parseDate(map['birthday']),
      photoUrl: photo == null || photo.isEmpty ? null : photo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'gender': gender,
      'birthday': birthday == null ? null : Timestamp.fromDate(birthday!),
      'photoUrl': photoUrl,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    String? gender,
    DateTime? birthday,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
