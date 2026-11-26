import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/user_avatar.dart';
import 'room_detail_screen.dart';

class TenantDetailScreen extends StatelessWidget {
  const TenantDetailScreen({super.key, required this.tenantId});

  final String tenantId;

  Room? _roomFor(List<Room> rooms) {
    for (final room in rooms) {
      if (room.tenantId == tenantId) return room;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tenantsProvider = context.watch<TenantsProvider>();
    final roomsProvider = context.watch<RoomsProvider>();
    final tenant = tenantsProvider.tenantById(tenantId);

    if (tenant == null) {
      final error = tenantsProvider.errorMessage;
      return Scaffold(
        appBar: AppBar(title: const Text('Tenant details')),
        body: tenantsProvider.isLoading
            ? const LoadingView(message: 'Loading tenant...')
            : error != null
            ? ErrorView(message: error, onRetry: tenantsProvider.retry)
            : const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Tenant not found',
                message: 'This tenant profile may no longer be available.',
              ),
      );
    }

    final room = _roomFor(roomsProvider.rooms);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tenant details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          _ProfileCard(tenant: tenant),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Contact information',
            subtitle: 'Registered account details',
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: tenant.email,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: tenant.phone.isEmpty ? 'Not provided' : tenant.phone,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: AppHelpers.formatDate(tenant.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Current room',
            subtitle: 'Room currently assigned to this tenant',
          ),
          const SizedBox(height: 8),
          if (room == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.meeting_room_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No room is assigned. Approve a reservation to assign '
                        'this tenant to a room.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            RoomCard(
              room: room,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RoomDetailScreen(roomId: room.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.tenant});

  final AppUser tenant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            UserAvatar(
              name: tenant.name,
              photoUrl: tenant.photoUrl,
              radius: 36,
            ),
            const SizedBox(height: 12),
            Text(
              tenant.name,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tenant.email,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Chip(
              avatar: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text('Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
