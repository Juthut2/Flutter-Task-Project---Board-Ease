import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosalada_project_board_ease/models/maintenance_request.dart';
import 'package:rosalada_project_board_ease/models/payment.dart';

void main() {
  test('Maintenance request maps round trip', () {
    final request = MaintenanceRequest(
      id: 'request-1',
      roomId: 'room-1',
      tenantId: 'tenant-1',
      title: 'Leaking faucet',
      description: 'The bathroom sink drips overnight.',
      photoUrl: 'https://res.cloudinary.com/demo/issue.jpg',
      status: MaintenanceStatus.inProgress,
      createdAt: DateTime(2026, 11, 24),
    );

    final map = request.toMap();
    final restored = MaintenanceRequest.fromMap('request-1', map);

    expect(map['createdAt'], isA<Timestamp>());
    expect(restored.id, 'request-1');
    expect(restored.roomId, request.roomId);
    expect(restored.tenantId, request.tenantId);
    expect(restored.title, request.title);
    expect(restored.photoUrl, request.photoUrl);
    expect(restored.status, MaintenanceStatus.inProgress);
    expect(restored.createdAt, request.createdAt);
  });

  test('Maintenance status falls back to pending for unknown values', () {
    expect(MaintenanceStatus.fromValue('resolved'), MaintenanceStatus.resolved);
    expect(
      MaintenanceStatus.fromValue('in_progress'),
      MaintenanceStatus.inProgress,
    );
    expect(MaintenanceStatus.fromValue('unknown'), MaintenanceStatus.pending);
    expect(MaintenanceStatus.fromValue(null), MaintenanceStatus.pending);
  });

  test('Maintenance copyWith can clear an optional photo', () {
    final request = MaintenanceRequest(
      roomId: 'room-1',
      tenantId: 'tenant-1',
      title: 'Broken light',
      description: 'Hallway light is out.',
      photoUrl: 'https://res.cloudinary.com/demo/light.jpg',
      status: MaintenanceStatus.pending,
      createdAt: DateTime(2026, 11, 24),
    );

    expect(request.copyWith(clearPhoto: true).photoUrl, isNull);
    expect(
      request.copyWith(status: MaintenanceStatus.resolved).photoUrl,
      request.photoUrl,
    );
  });

  test('Payment maps round trip with a pending status', () {
    final payment = Payment(
      id: 'payment-1',
      roomId: 'room-1',
      tenantId: 'tenant-1',
      amount: 4500,
      month: '2026-11',
      proofUrl: 'https://res.cloudinary.com/demo/proof.jpg',
      status: PaymentStatus.pending,
      createdAt: DateTime(2026, 11, 24),
    );

    final map = payment.toMap();
    final restored = Payment.fromMap('payment-1', map);

    expect(map['createdAt'], isA<Timestamp>());
    expect(restored.id, 'payment-1');
    expect(restored.amount, 4500);
    expect(restored.month, '2026-11');
    expect(restored.status, PaymentStatus.pending);
    expect(restored.proofUrl, payment.proofUrl);
  });
}
