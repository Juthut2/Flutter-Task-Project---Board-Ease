import 'package:flutter_test/flutter_test.dart';
import 'package:rosalada_project_board_ease/core/tenant_rental.dart';
import 'package:rosalada_project_board_ease/models/payment.dart';
import 'package:rosalada_project_board_ease/models/reservation.dart';
import 'package:rosalada_project_board_ease/models/room.dart';

void main() {
  final now = DateTime(2026, 11, 23, 9);

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
    ReservationStatus status = ReservationStatus.approved,
    DateTime? createdAt,
    DateTime? moveInDate,
  }) {
    return Reservation(
      id: id,
      roomId: roomId,
      tenantId: 'tenant-1',
      status: status,
      moveInDate: moveInDate ?? DateTime(2026, 11, 1),
      createdAt: createdAt ?? DateTime(2026, 10, 20),
    );
  }

  Payment payment({
    required String id,
    required String roomId,
    required String month,
    required PaymentStatus status,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id,
      roomId: roomId,
      tenantId: 'tenant-1',
      amount: 5000,
      month: month,
      proofUrl: 'https://res.cloudinary.com/demo/image/upload/proof.jpg',
      status: status,
      createdAt: createdAt ?? DateTime(2026, 11, 5),
    );
  }

  test('resolves the assigned room and current month due', () {
    final rental = TenantRentalSummary.active(
      tenantId: 'tenant-1',
      now: now,
      rooms: <Room>[
        room(id: 'a', status: RoomStatus.occupied, tenantId: 'tenant-1'),
      ],
      reservations: <Reservation>[reservation(id: 'r1', roomId: 'a')],
      payments: const <Payment>[],
    );

    expect(rental, isNotNull);
    expect(rental!.room.id, 'a');
    expect(rental.reservation.id, 'r1');
    expect(rental.dueMonth, '2026-11');
    expect(rental.isPaid, isFalse);
    expect(rental.hasPendingPayment, isFalse);
    expect(rental.isDue, isTrue);
  });

  test('marks the current month paid and moves the due month forward', () {
    final rental = TenantRentalSummary.active(
      tenantId: 'tenant-1',
      now: now,
      rooms: <Room>[
        room(id: 'a', status: RoomStatus.occupied, tenantId: 'tenant-1'),
      ],
      reservations: <Reservation>[reservation(id: 'r1', roomId: 'a')],
      payments: <Payment>[
        payment(
          id: 'p1',
          roomId: 'a',
          month: '2026-11',
          status: PaymentStatus.verified,
        ),
      ],
    );

    expect(rental!.isPaid, isTrue);
    expect(rental.hasPendingPayment, isFalse);
    expect(rental.dueMonth, '2026-12');
  });

  test('detects a pending payment for the current month', () {
    final rental = TenantRentalSummary.active(
      tenantId: 'tenant-1',
      now: now,
      rooms: <Room>[
        room(id: 'a', status: RoomStatus.occupied, tenantId: 'tenant-1'),
      ],
      reservations: <Reservation>[reservation(id: 'r1', roomId: 'a')],
      payments: <Payment>[
        payment(
          id: 'p1',
          roomId: 'a',
          month: '2026-11',
          status: PaymentStatus.pending,
        ),
      ],
    );

    expect(rental!.isPaid, isFalse);
    expect(rental.hasPendingPayment, isTrue);
    expect(rental.isDue, isFalse);
    expect(rental.dueMonth, '2026-11');
  });

  test('ignores approved reservations without an assigned room', () {
    final rental = TenantRentalSummary.active(
      tenantId: 'tenant-1',
      now: now,
      rooms: <Room>[
        room(id: 'a'),
        room(id: 'b'),
      ],
      reservations: <Reservation>[
        reservation(id: 'older', roomId: 'a', createdAt: DateTime(2026, 9, 1)),
        reservation(id: 'newer', roomId: 'b', createdAt: DateTime(2026, 10, 1)),
        reservation(
          id: 'declined',
          roomId: 'a',
          status: ReservationStatus.declined,
          createdAt: DateTime(2026, 11, 1),
        ),
      ],
      payments: const <Payment>[],
    );

    expect(rental, isNull);
  });

  test('returns null when there is no approved reservation', () {
    final rental = TenantRentalSummary.active(
      tenantId: 'tenant-1',
      now: now,
      rooms: <Room>[room(id: 'a')],
      reservations: <Reservation>[
        reservation(id: 'r1', roomId: 'a', status: ReservationStatus.pending),
      ],
      payments: const <Payment>[],
    );

    expect(rental, isNull);
  });

  test(
    'blocking reservations ignore approved, declined, and cancelled requests',
    () {
      final reservations = <Reservation>[
        reservation(
          id: 'approved',
          roomId: 'a',
          status: ReservationStatus.approved,
        ),
        reservation(
          id: 'declined',
          roomId: 'a',
          status: ReservationStatus.declined,
        ),
        reservation(
          id: 'cancelled',
          roomId: 'a',
          status: ReservationStatus.cancelled,
        ),
      ];
      expect(
        TenantRentalSummary.blockingReservation(reservations, 'a'),
        isNull,
      );

      reservations.add(
        reservation(
          id: 'pending',
          roomId: 'a',
          status: ReservationStatus.pending,
        ),
      );
      expect(
        TenantRentalSummary.blockingReservation(reservations, 'a')?.id,
        'pending',
      );
    },
  );

  test('paymentForMonth returns the most recent matching payment', () {
    final latest = TenantRentalSummary.paymentForMonth(
      payments: <Payment>[
        payment(
          id: 'old',
          roomId: 'a',
          month: '2026-11',
          status: PaymentStatus.rejected,
          createdAt: DateTime(2026, 11, 1),
        ),
        payment(
          id: 'new',
          roomId: 'a',
          month: '2026-11',
          status: PaymentStatus.pending,
          createdAt: DateTime(2026, 11, 9),
        ),
        payment(
          id: 'other',
          roomId: 'b',
          month: '2026-11',
          status: PaymentStatus.verified,
        ),
      ],
      roomId: 'a',
      month: '2026-11',
    );

    expect(latest?.id, 'new');
  });
}
