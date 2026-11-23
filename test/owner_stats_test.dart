import 'package:flutter_test/flutter_test.dart';
import 'package:rosalada_project_board_ease/core/owner_stats.dart';
import 'package:rosalada_project_board_ease/models/payment.dart';
import 'package:rosalada_project_board_ease/models/reservation.dart';
import 'package:rosalada_project_board_ease/models/room.dart';

void main() {
  final now = DateTime(2026, 11, 23, 10);

  Room room({
    required String id,
    RoomStatus status = RoomStatus.available,
    String? tenantId,
  }) {
    return Room(
      id: id,
      ownerId: 'owner-1',
      name: 'Room $id',
      monthlyRate: 5000,
      deposit: 5000,
      capacity: 1,
      status: status,
      tenantId: tenantId,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Reservation reservation({
    required String id,
    required String roomId,
    required String tenantId,
    required ReservationStatus status,
    DateTime? moveInDate,
  }) {
    return Reservation(
      id: id,
      roomId: roomId,
      tenantId: tenantId,
      status: status,
      moveInDate: moveInDate ?? DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 10, 20),
    );
  }

  Payment payment({
    required String id,
    required String roomId,
    required String tenantId,
    required double amount,
    required String month,
    PaymentStatus status = PaymentStatus.verified,
  }) {
    return Payment(
      id: id,
      roomId: roomId,
      tenantId: tenantId,
      amount: amount,
      month: month,
      proofUrl: 'https://res.cloudinary.com/demo/image/upload/proof.jpg',
      status: status,
      createdAt: DateTime(2026, 11, 5),
    );
  }

  test('counts rooms, occupancy, and pending requests', () {
    final stats = OwnerStats.compute(
      now: now,
      rooms: <Room>[
        room(id: 'a'),
        room(id: 'b', status: RoomStatus.reserved, tenantId: 't2'),
        room(id: 'c', status: RoomStatus.occupied, tenantId: 't3'),
      ],
      reservations: <Reservation>[
        reservation(
          id: 'r1',
          roomId: 'a',
          tenantId: 't1',
          status: ReservationStatus.pending,
        ),
        reservation(
          id: 'r2',
          roomId: 'b',
          tenantId: 't2',
          status: ReservationStatus.pending,
        ),
        reservation(
          id: 'r3',
          roomId: 'c',
          tenantId: 't3',
          status: ReservationStatus.approved,
        ),
        reservation(
          id: 'r4',
          roomId: 'other',
          tenantId: 't4',
          status: ReservationStatus.pending,
        ),
      ],
      payments: const <Payment>[],
    );

    expect(stats.totalRooms, 3);
    expect(stats.availableRooms, 1);
    expect(stats.reservedRooms, 1);
    expect(stats.occupiedRooms, 1);
    expect(stats.pendingReservations, 2);
  });

  test('sums only verified payments for the current month', () {
    final stats = OwnerStats.compute(
      now: now,
      rooms: <Room>[room(id: 'a', status: RoomStatus.occupied, tenantId: 't1')],
      reservations: const <Reservation>[],
      payments: <Payment>[
        payment(
          id: 'p1',
          roomId: 'a',
          tenantId: 't1',
          amount: 5000,
          month: '2026-11',
        ),
        payment(
          id: 'p2',
          roomId: 'a',
          tenantId: 't1',
          amount: 1000,
          month: '2026-11',
          status: PaymentStatus.pending,
        ),
        payment(
          id: 'p3',
          roomId: 'a',
          tenantId: 't1',
          amount: 2000,
          month: '2026-10',
        ),
        payment(
          id: 'p4',
          roomId: 'other',
          tenantId: 't9',
          amount: 3000,
          month: '2026-11',
        ),
      ],
    );

    expect(stats.monthlyCollections, 5000);
    expect(stats.overdueTenants, 0);
  });

  test('flags occupied tenants without a verified payment', () {
    final stats = OwnerStats.compute(
      now: now,
      rooms: <Room>[room(id: 'a', status: RoomStatus.occupied, tenantId: 't1')],
      reservations: const <Reservation>[],
      payments: const <Payment>[],
    );

    expect(stats.overdueTenants, 1);
    expect(stats.overdueRooms.single.id, 'a');
  });

  test('does not flag a tenant whose move-in is still in the future', () {
    final stats = OwnerStats.compute(
      now: now,
      rooms: <Room>[room(id: 'a', status: RoomStatus.occupied, tenantId: 't1')],
      reservations: <Reservation>[
        reservation(
          id: 'r1',
          roomId: 'a',
          tenantId: 't1',
          status: ReservationStatus.approved,
          moveInDate: DateTime(2026, 12, 1),
        ),
      ],
      payments: const <Payment>[],
    );

    expect(stats.overdueTenants, 0);
  });

  test('does not flag reserved rooms without payments', () {
    final stats = OwnerStats.compute(
      now: now,
      rooms: <Room>[room(id: 'a', status: RoomStatus.reserved, tenantId: 't1')],
      reservations: const <Reservation>[],
      payments: const <Payment>[],
    );

    expect(stats.overdueTenants, 0);
  });
}
