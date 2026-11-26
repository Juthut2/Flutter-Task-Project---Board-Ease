import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/user_avatar.dart';
import 'tenant_detail_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _visibleCount = AppConstants.pageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filtered(List<AppUser> tenants) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return tenants;
    return tenants
        .where(
          (tenant) =>
              tenant.name.toLowerCase().contains(query) ||
              tenant.email.toLowerCase().contains(query) ||
              tenant.phone.toLowerCase().contains(query),
        )
        .toList();
  }

  Room? _roomFor(List<Room> rooms, String tenantId) {
    for (final room in rooms) {
      if (room.tenantId == tenantId) return room;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tenantsProvider = context.watch<TenantsProvider>();
    final roomsProvider = context.watch<RoomsProvider>();
    final tenants = _filtered(tenantsProvider.tenants);
    final visible = tenants.take(_visibleCount).toList();
    final remaining = tenants.length - visible.length;
    final hasTenants = tenantsProvider.tenants.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search tenants by name, email, or phone',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _visibleCount = AppConstants.pageSize;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: (value) => setState(() {
              _query = value;
              _visibleCount = AppConstants.pageSize;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.people_outline_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                hasTenants
                    ? '${tenantsProvider.tenants.length} registered '
                          '${tenantsProvider.tenants.length == 1 ? 'tenant' : 'tenants'}'
                    : 'Tenant directory',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              tenantsProvider.retry();
              roomsProvider.retry();
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: <Widget>[
                if (tenantsProvider.errorMessage != null)
                  ErrorView(
                    message: tenantsProvider.errorMessage!,
                    onRetry: tenantsProvider.retry,
                  ),
                if (tenantsProvider.isLoading && !hasTenants)
                  const LoadingView(message: 'Loading tenants...')
                else if (tenants.isEmpty)
                  EmptyState(
                    icon: hasTenants
                        ? Icons.search_off_rounded
                        : Icons.people_outline_rounded,
                    title: hasTenants
                        ? 'No matching tenants'
                        : 'No tenants yet',
                    message: hasTenants
                        ? 'Try a different name, email, or phone number.'
                        : 'Tenants appear here after they register and verify '
                              'their email.',
                  )
                else
                  for (final tenant in visible) ...<Widget>[
                    _TenantTile(
                      tenant: tenant,
                      room: _roomFor(roomsProvider.rooms, tenant.uid),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TenantDetailScreen(tenantId: tenant.uid),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                if (remaining > 0)
                  LoadMoreButton(
                    remaining: remaining,
                    onPressed: () =>
                        setState(() => _visibleCount += AppConstants.pageSize),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TenantTile extends StatelessWidget {
  const _TenantTile({
    required this.tenant,
    required this.room,
    required this.onTap,
  });

  final AppUser tenant;
  final Room? room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: UserAvatar(
          name: tenant.name,
          photoUrl: tenant.photoUrl,
          radius: 22,
        ),
        title: Text(
          tenant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 2),
            Text(
              tenant.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: <Widget>[
                Icon(
                  room == null
                      ? Icons.meeting_room_outlined
                      : Icons.home_work_outlined,
                  size: 14,
                  color: room == null
                      ? scheme.onSurfaceVariant
                      : scheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    room == null ? 'No room assigned' : room!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: room == null
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
