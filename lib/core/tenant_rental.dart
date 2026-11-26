import '../models/payment.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'helpers.dart';

/// The tenant's active rental plus this month's payment state.
class TenantRental {
  const TenantRental({
    required this.reservation,
    required this.room,
    required this.dueMonth,
    this.verifiedPayment,
    this.pendingPayment,
  });

  final Reservation reservation;
  final Room room;
  final String dueMonth;
  final Payment? verifiedPayment;
  final Payment? pendingPayment;

  bool get isPaid => verifiedPayment != null;

  bool get hasPendingPayment => pendingPayment != null;

  bool get isDue => !isPaid && !hasPendingPayment;
}

/// Resolves a tenant's active rental from live rooms, reservations, and payments.
class TenantRentalSummary {
  const TenantRentalSummary._();

  static TenantRental? active({
    required String tenantId,
    required List<Reservation> reservations,
    required List<Room> rooms,
    required List<Payment> payments,
    DateTime? now,
  }) {
    if (tenantId.isEmpty) return null;
    final current = now ?? DateTime.now();
    final month = AppHelpers.monthKey(current);

    final room = _assignedRoom(rooms, tenantId);
    if (room == null) return null;

    final approved = reservations
        .where(
          (item) =>
              item.status == ReservationStatus.approved &&
              item.roomId == room.id,
        )
        .toList();
    final activeReservation = _latest(approved);
    if (activeReservation == null) return null;

    Payment? verified;
    Payment? pending;
    for (final payment in payments) {
      if (payment.tenantId != tenantId) continue;
      if (payment.roomId != room.id) continue;
      if (payment.month != month) continue;
      if (payment.status == PaymentStatus.verified) {
        verified = _latestPayment(verified, payment);
      } else if (payment.status == PaymentStatus.pending) {
        pending = _latestPayment(pending, payment);
      }
    }

    final dueMonth = verified != null
        ? AppHelpers.monthKey(DateTime(current.year, current.month + 1))
        : month;

    return TenantRental(
      reservation: activeReservation,
      room: room,
      dueMonth: dueMonth,
      verifiedPayment: verified,
      pendingPayment: pending,
    );
  }

  /// The pending reservation that blocks a new request for [roomId].
  static Reservation? blockingReservation(
    List<Reservation> reservations,
    String roomId,
  ) {
    for (final reservation in reservations) {
      if (reservation.roomId != roomId) continue;
      if (reservation.status == ReservationStatus.pending) {
        return reservation;
      }
    }
    return null;
  }

  static Payment? paymentForMonth({
    required List<Payment> payments,
    required String roomId,
    required String month,
  }) {
    Payment? latest;
    for (final payment in payments) {
      if (payment.roomId != roomId || payment.month != month) continue;
      latest = _latestPayment(latest, payment);
    }
    return latest;
  }

  static Room? _assignedRoom(List<Room> rooms, String tenantId) {
    for (final room in rooms) {
      if (room.tenantId == tenantId && room.status != RoomStatus.available) {
        return room;
      }
    }
    return null;
  }

  static Reservation? _latest(List<Reservation> reservations) {
    Reservation? latest;
    for (final reservation in reservations) {
      latest = _latestReservation(latest, reservation);
    }
    return latest;
  }

  static Reservation? _latestReservation(
    Reservation? current,
    Reservation candidate,
  ) {
    if (current == null) return candidate;
    return candidate.createdAt.isAfter(current.createdAt) ? candidate : current;
  }

  static Payment? _latestPayment(Payment? current, Payment candidate) {
    if (current == null) return candidate;
    return candidate.createdAt.isAfter(current.createdAt) ? candidate : current;
  }
}
