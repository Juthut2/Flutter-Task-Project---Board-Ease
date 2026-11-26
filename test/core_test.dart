import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosalada_project_board_ease/core/validators.dart';
import 'package:rosalada_project_board_ease/models/app_user.dart';
import 'package:rosalada_project_board_ease/models/room.dart';

void main() {
  group('Validators', () {
    test('email rejects malformed values', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('tenant@example.com'), isNull);
    });

    test('password needs eight characters, a letter, and a number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('abcdefg1'), isNull);
    });

    test('phone accepts Philippine mobile formats', () {
      expect(Validators.phone('09171234567'), isNull);
      expect(Validators.phone('+639171234567'), isNull);
      expect(Validators.phone('12345'), isNotNull);
    });

    test('amount must be positive', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
      expect(Validators.amount('4500'), isNull);
    });

    test('birthday requires an adult and no future date', () {
      final now = DateTime.now();
      expect(Validators.birthday(null), isNotNull);
      expect(
        Validators.birthday(DateTime(now.year - 20, now.month, now.day)),
        isNull,
      );
      expect(
        Validators.birthday(DateTime(now.year - 17, now.month, now.day)),
        isNotNull,
      );
      expect(Validators.birthday(now.add(const Duration(days: 1))), isNotNull);
    });
  });

  test('AppUser reads old profiles without profile fields', () {
    final user = AppUser.fromMap('user-1', <String, dynamic>{
      'name': 'Old Tenant',
      'email': 'old@example.com',
      'phone': '',
      'role': 'tenant',
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
    });

    expect(user.gender, isNull);
    expect(user.birthday, isNull);
    expect(user.photoUrl, isNull);
    expect(user.hasCompleteProfile, isFalse);
  });

  test('AppUser profile fields round trip', () {
    final user = AppUser(
      uid: 'user-2',
      name: 'Ana Cruz',
      email: 'ana@example.com',
      phone: '09171234567',
      role: UserRole.tenant,
      createdAt: DateTime(2026, 1, 1),
      gender: 'female',
      birthday: DateTime(1998, 5, 20),
      photoUrl: 'https://res.cloudinary.com/demo/ana.jpg',
    );

    final map = user.toMap();
    final restored = AppUser.fromMap('user-2', map);

    expect(map['birthday'], isA<Timestamp>());
    expect(restored.gender, 'female');
    expect(restored.birthday, DateTime(1998, 5, 20));
    expect(restored.photoUrl, user.photoUrl);
    expect(restored.hasCompleteProfile, isTrue);
  });

  test('Room maps round trip', () {
    final room = Room(
      id: 'room-1',
      ownerId: 'owner-1',
      name: 'Sunny Studio',
      description: 'A bright studio near the campus.',
      monthlyRate: 4500,
      deposit: 4500,
      capacity: 2,
      amenities: const ['WiFi', 'Aircon'],
      rules: 'No smoking indoors.',
      photos: const ['https://res.cloudinary.com/demo/room.jpg'],
      status: RoomStatus.available,
      province: 'Laguna',
      city: 'Santa Rosa',
      barangay: 'Balibago',
      street: '12 Mabini Street',
      createdAt: DateTime(2026, 11, 21),
    );

    final map = room.toMap();
    final restored = Room.fromMap('room-1', map);

    expect(map['createdAt'], isA<Timestamp>());
    expect(restored.id, 'room-1');
    expect(restored.name, room.name);
    expect(restored.monthlyRate, room.monthlyRate);
    expect(restored.amenities, room.amenities);
    expect(restored.tenantId, isNull);
    expect(restored.status, RoomStatus.available);
    expect(restored.fullAddress, contains('Balibago'));
  });
}
