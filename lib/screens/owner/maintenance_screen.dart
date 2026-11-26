import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../models/maintenance_request.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/maintenance_request_card.dart';

/// Owner queue for tenant maintenance requests.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  MaintenanceStatus? _filter = MaintenanceStatus.pending;
  String? _busyId;
  int _visibleCount = AppConstants.pageSize;

  Future<void> _update(
    MaintenanceRequest request,
    MaintenanceStatus status,
  ) async {
    setState(() => _busyId = request.id);
    try {
      await context.read<MaintenanceProvider>().updateStatus(request, status);
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Request marked ${status.label.toLowerCase()}.',
      );
    } on MaintenanceFailure catch (error) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Could not update the request. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaintenanceProvider>();
    final roomsProvider = context.watch<RoomsProvider>();
    final tenantsProvider = context.watch<TenantsProvider>();

    final roomIds = roomsProvider.rooms.map((room) => room.id).toSet();
    final scoped = provider.requests
        .where((item) => roomIds.contains(item.roomId))
        .toList();
    final visible = scoped
        .where((item) => _filter == null || item.status == _filter)
        .toList();
    final paged = visible.take(_visibleCount).toList();
    final remaining = visible.length - paged.length;
    final error = provider.errorMessage ?? roomsProvider.errorMessage;
    final loading =
        (provider.isLoading && scoped.isEmpty) ||
        (roomsProvider.isLoading && roomsProvider.rooms.isEmpty);

    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: <Widget>[
              for (final option in <MaintenanceStatus?>[
                MaintenanceStatus.pending,
                MaintenanceStatus.inProgress,
                MaintenanceStatus.resolved,
                null,
              ]) ...<Widget>[
                if (option != MaintenanceStatus.pending)
                  const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_filterLabel(option, scoped)),
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
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              provider.retry();
              roomsProvider.retry();
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: <Widget>[
                if (error != null)
                  ErrorView(
                    message: error,
                    onRetry: () {
                      provider.retry();
                      roomsProvider.retry();
                    },
                  ),
                if (loading)
                  const LoadingView(message: 'Loading maintenance requests...')
                else if (visible.isEmpty)
                  EmptyState(
                    icon: Icons.build_outlined,
                    title: _filter == MaintenanceStatus.pending
                        ? 'No open requests'
                        : 'No requests here yet',
                    message: _filter == MaintenanceStatus.pending
                        ? 'Tenant maintenance requests will appear here.'
                        : 'Requests with this status will appear here.',
                  )
                else
                  for (final request in paged) ...<Widget>[
                    MaintenanceRequestCard(
                      request: request,
                      roomName:
                          roomsProvider.roomById(request.roomId)?.name ??
                          'Room removed',
                      tenantName:
                          tenantsProvider.tenantById(request.tenantId)?.name ??
                          'Tenant',
                      tenantPhotoUrl: tenantsProvider
                          .tenantById(request.tenantId)
                          ?.photoUrl,
                      busy: _busyId == request.id,
                      onStatusChanged: (status) => _update(request, status),
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

  String _filterLabel(
    MaintenanceStatus? status,
    List<MaintenanceRequest> requests,
  ) {
    final label = status?.label ?? 'All';
    final count = status == null
        ? requests.length
        : requests.where((item) => item.status == status).length;
    return count == 0 ? label : '$label ($count)';
  }
}
