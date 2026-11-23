import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/app_user.dart';
import '../models/room.dart';
import 'room_info_card.dart';
import 'room_owner_actions.dart';
import 'room_photo_gallery.dart';
import 'section_header.dart';
import 'status_chip.dart';
import 'tenant_summary_card.dart';

/// Scrollable room details body with owner actions.
class RoomDetailBody extends StatelessWidget {
  const RoomDetailBody({
    super.key,
    required this.room,
    required this.tenant,
    this.onEdit,
    this.onMarkAvailable,
    required this.onDelete,
    required this.onViewTenant,
  });

  final Room room;
  final AppUser? tenant;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkAvailable;
  final VoidCallback onDelete;
  final VoidCallback onViewTenant;

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
              'Added ${AppHelpers.formatDate(room.createdAt)}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          room.name,
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
                label: 'Monthly rate',
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
        if (tenant != null) ...[
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Current tenant',
            action: TextButton(
              onPressed: onViewTenant,
              child: const Text('View'),
            ),
          ),
          const SizedBox(height: 8),
          TenantSummaryCard(tenant: tenant!),
        ] else if (room.tenantId != null) ...[
          const SizedBox(height: 16),
          Text(
            'Tenant profile is unavailable. It may still be loading.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
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
        RoomOwnerActions(
          onEdit: onEdit,
          onMarkAvailable: onMarkAvailable,
          onDelete: onDelete,
        ),
      ],
    );
  }
}
