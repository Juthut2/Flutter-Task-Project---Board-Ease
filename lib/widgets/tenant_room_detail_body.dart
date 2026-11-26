import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'room_info_card.dart';
import 'room_photo_gallery.dart';
import 'section_header.dart';
import 'status_chip.dart';

/// Tenant-facing room details body with the reservation call to action.
class TenantRoomDetailBody extends StatelessWidget {
  const TenantRoomDetailBody({
    super.key,
    required this.room,
    required this.blocking,
    required this.hasActiveRental,
    required this.canReserve,
    required this.onReserve,
  });

  final Room room;
  final Reservation? blocking;
  final bool hasActiveRental;
  final bool canReserve;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        RoomPhotoGallery(photos: room.photos),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            StatusChip.room(room.status),
            const Spacer(),
            Text(
              'Listed ${AppHelpers.formatDate(room.createdAt)}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          room.name.isEmpty ? 'Untitled room' : room.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                room.fullAddress.isEmpty ? 'Address not set' : room.fullAddress,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: RoomInfoCard(
                label: 'Monthly rent',
                value: AppHelpers.formatCurrency(room.monthlyRate),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RoomInfoCard(
                label: 'Deposit',
                value: AppHelpers.formatCurrency(room.deposit),
                icon: Icons.savings_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RoomInfoCard(
          label: 'Capacity',
          value: '${room.capacity} ${room.capacity == 1 ? 'person' : 'people'}',
          icon: Icons.people_outline_rounded,
          horizontal: true,
        ),
        if (blocking != null) ...[
          const SizedBox(height: 18),
          _ReservationNotice(reservation: blocking!),
        ],
        if (hasActiveRental && blocking == null) ...[
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'You already have an active rental. End it before reserving '
                'another room.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.error),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionHeader(title: 'Description'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              room.description.isEmpty
                  ? 'No description provided.'
                  : room.description,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        if (room.amenities.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Amenities'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: room.amenities
                .map((amenity) => Chip(label: Text(amenity)))
                .toList(),
          ),
        ],
        if (room.rules.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'House rules'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(room.rules, style: textTheme.bodyMedium),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: canReserve ? onReserve : null,
          icon: const Icon(Icons.event_available_rounded),
          label: Text(_buttonLabel()),
        ),
        const SizedBox(height: 8),
        Text(
          canReserve
              ? 'The owner reviews every request before it is confirmed.'
              : 'Reservation is unavailable for this room right now.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _buttonLabel() {
    if (!room.isAvailable) return 'Not available';
    if (blocking != null) {
      return blocking!.status == ReservationStatus.pending
          ? 'Request pending'
          : 'You rent this room';
    }
    if (hasActiveRental) return 'Active rental exists';
    return 'Reserve this room';
  }
}

class _ReservationNotice extends StatelessWidget {
  const _ReservationNotice({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pending = reservation.status == ReservationStatus.pending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            StatusChip.reservation(reservation.status),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pending
                    ? 'Your request is waiting for owner approval.'
                    : 'This is your current rental.',
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
