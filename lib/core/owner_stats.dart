import '../models/payment.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'helpers.dart';

/// Dashboard totals derived from an owner's rooms and their activity.
class OwnerStats {
  const OwnerStats({
    required this.totalRooms,
    required this.availableRooms,
    required this.reservedRooms,
    required this.occupiedRooms,
    required this.pendingReservations,
    required this.overdueTenants,
    required this.monthlyCollections,
    required this.overdueRooms,
  });

  final int totalRooms;
  final int availableRooms;
  final int reservedRooms;
  final int occupiedRooms;
  final int pendingReservations;
  final int overdueTenants;
  final double monthlyCollections;
  final List<Room> overdueRooms;

  factory OwnerStats.compute({
    required List<Room> rooms,
    required List<Reservation> reservations,
    required List<Payment> payments,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final month = AppHelpers.monthKey(clock);
    final roomIds = rooms.map((room) => room.id).toSet();
    final ownerReservations = reservations
        .where((item) => roomIds.contains(item.roomId))
        .toList();
    final ownerPayments = payments
        .where((item) => roomIds.contains(item.roomId))
        .toList();

    var available = 0;
    var reserved = 0;
    var occupied = 0;
    for (final room in rooms) {
      switch (room.status) {
        case RoomStatus.available:
          available += 1;
        case RoomStatus.reserved:
          reserved += 1;
        case RoomStatus.occupied:
          occupied += 1;
      }
    }

    var pending = 0;
    for (final item in ownerReservations) {
      if (item.status == ReservationStatus.pending) pending += 1;
    }

    var collections = 0.0;
    for (final payment in ownerPayments) {
      if (payment.status == PaymentStatus.verified && payment.month == month) {
        collections += payment.amount;
      }
    }

    final overdueRooms = <Room>[];
    for (final room in rooms) {
      if (room.status != RoomStatus.occupied || room.tenantId == null) {
        continue;
      }
      final paid = ownerPayments.any(
        (payment) =>
            payment.roomId == room.id &&
            payment.status == PaymentStatus.verified &&
            payment.month == month,
      );
      if (paid) continue;

      Reservation? latestApproved;
      for (final item in ownerReservations) {
        if (item.roomId == room.id &&
            item.tenantId == room.tenantId &&
            item.status == ReservationStatus.approved) {
          if (latestApproved == null ||
              item.createdAt.isAfter(latestApproved.createdAt)) {
            latestApproved = item;
          }
        }
      }
      if (latestApproved != null && latestApproved.moveInDate.isAfter(clock)) {
        continue;
      }
      overdueRooms.add(room);
    }

    return OwnerStats(
      totalRooms: rooms.length,
      availableRooms: available,
      reservedRooms: reserved,
      occupiedRooms: occupied,
      pendingReservations: pending,
      overdueTenants: overdueRooms.length,
      monthlyCollections: collections,
      overdueRooms: overdueRooms,
    );
  }
}
