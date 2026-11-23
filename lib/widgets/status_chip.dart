import 'package:material_ui/material_ui.dart';

import '../models/maintenance_request.dart';
import '../models/payment.dart';
import '../models/reservation.dart';
import '../models/room.dart';

/// Compact colored status pill used across owner and tenant screens.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusChip.room(RoomStatus status) {
    return switch (status) {
      RoomStatus.available => const StatusChip(
        label: 'Available',
        color: Color(0xFF137A5B),
        icon: Icons.check_circle_outline_rounded,
      ),
      RoomStatus.reserved => const StatusChip(
        label: 'Reserved',
        color: Color(0xFFB26A00),
        icon: Icons.schedule_rounded,
      ),
      RoomStatus.occupied => const StatusChip(
        label: 'Occupied',
        color: Color(0xFF2563EB),
        icon: Icons.person_outline_rounded,
      ),
    };
  }

  factory StatusChip.reservation(ReservationStatus status) {
    return switch (status) {
      ReservationStatus.pending => StatusChip(
        label: status.label,
        color: const Color(0xFFB26A00),
        icon: Icons.hourglass_top_rounded,
      ),
      ReservationStatus.approved => StatusChip(
        label: status.label,
        color: const Color(0xFF137A5B),
        icon: Icons.check_circle_outline_rounded,
      ),
      ReservationStatus.declined => StatusChip(
        label: status.label,
        color: const Color(0xFFB3261E),
        icon: Icons.cancel_outlined,
      ),
      ReservationStatus.cancelled => StatusChip(
        label: status.label,
        color: const Color(0xFF6B7280),
        icon: Icons.block_rounded,
      ),
    };
  }

  factory StatusChip.payment(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.pending => StatusChip(
        label: status.label,
        color: const Color(0xFFB26A00),
        icon: Icons.hourglass_top_rounded,
      ),
      PaymentStatus.verified => StatusChip(
        label: status.label,
        color: const Color(0xFF137A5B),
        icon: Icons.verified_outlined,
      ),
      PaymentStatus.rejected => StatusChip(
        label: status.label,
        color: const Color(0xFFB3261E),
        icon: Icons.cancel_outlined,
      ),
    };
  }

  factory StatusChip.maintenance(MaintenanceStatus status) {
    return switch (status) {
      MaintenanceStatus.pending => StatusChip(
        label: status.label,
        color: const Color(0xFFB26A00),
        icon: Icons.hourglass_top_rounded,
      ),
      MaintenanceStatus.inProgress => StatusChip(
        label: status.label,
        color: const Color(0xFF2563EB),
        icon: Icons.build_outlined,
      ),
      MaintenanceStatus.resolved => StatusChip(
        label: status.label,
        color: const Color(0xFF137A5B),
        icon: Icons.check_circle_outline_rounded,
      ),
    };
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
