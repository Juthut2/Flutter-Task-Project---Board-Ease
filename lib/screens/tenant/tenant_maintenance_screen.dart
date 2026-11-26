import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/tenant_rental.dart';
import '../../models/maintenance_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_maintenance_provider.dart';
import '../../providers/tenant_payments_provider.dart';
import '../../providers/tenant_reservations_provider.dart';
import '../../providers/tenant_rooms_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/maintenance_request_card.dart';
import 'maintenance_form_screen.dart';

/// Tenant list of maintenance requests for the active rental.
class TenantMaintenanceScreen extends StatefulWidget {
  const TenantMaintenanceScreen({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  State<TenantMaintenanceScreen> createState() =>
      _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  MaintenanceStatus? _filter;
  int _visibleCount = AppConstants.pageSize;

  Future<void> _openForm(TenantRental? rental) async {
    if (rental == null) {
      AppHelpers.showSnackBar(
        context,
        'Maintenance requests are available once you have an active rental.',
        isError: true,
      );
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MaintenanceFormScreen(rental: rental),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenantMaintenanceProvider>();
    final roomsProvider = context.watch<TenantRoomsProvider>();
    final reservationsProvider = context.watch<TenantReservationsProvider>();
    final paymentsProvider = context.watch<TenantPaymentsProvider>();
    final user = context.watch<AuthProvider>().user;

    final rental = user == null
        ? null
        : TenantRentalSummary.active(
            tenantId: user.uid,
            reservations: reservationsProvider.reservations,
            rooms: roomsProvider.rooms,
            payments: paymentsProvider.payments,
          );

    final requests = provider.requests;
    final visible = requests
        .where((item) => _filter == null || item.status == _filter)
        .toList();
    final paged = visible.take(_visibleCount).toList();
    final remaining = visible.length - paged.length;
    final error =
        provider.errorMessage ??
        roomsProvider.errorMessage ??
        reservationsProvider.errorMessage;
    final loading =
        (provider.isLoading && requests.isEmpty) ||
        (roomsProvider.isLoading && roomsProvider.rooms.isEmpty);

    return RefreshIndicator(
      onRefresh: () async {
        provider.retry();
        roomsProvider.retry();
        reservationsProvider.retry();
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Report an issue with your room or building.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _openForm(rental),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            ErrorView(
              message: error,
              onRetry: () {
                provider.retry();
                roomsProvider.retry();
                reservationsProvider.retry();
              },
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final option in <MaintenanceStatus?>[
                  null,
                  MaintenanceStatus.pending,
                  MaintenanceStatus.inProgress,
                  MaintenanceStatus.resolved,
                ]) ...<Widget>[
                  if (option != null) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(option?.label ?? 'All'),
                    selected: _filter == option,
                    onSelected: (_) => setState(() {
                      _filter = option;
                      _visibleCount = AppConstants.pageSize;
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const LoadingView(message: 'Loading your requests...')
          else if (rental == null && requests.isEmpty)
            EmptyState(
              icon: Icons.build_outlined,
              title: 'No active rental',
              message:
                  'Once your reservation is approved, you can report '
                  'maintenance issues for your room here.',
              action: FilledButton.icon(
                onPressed: widget.onBrowse,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse rooms'),
              ),
            )
          else if (visible.isEmpty)
            EmptyState(
              icon: Icons.build_outlined,
              title: 'No requests here',
              message: requests.isEmpty
                  ? 'Report a leaking faucet, wiring issue, or other problem '
                        'using the New button.'
                  : 'No maintenance requests match this filter.',
            )
          else
            for (final request in paged) ...<Widget>[
              MaintenanceRequestCard(
                request: request,
                roomName:
                    roomsProvider.roomById(request.roomId)?.name ??
                    'Room unavailable',
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
    );
  }
}
