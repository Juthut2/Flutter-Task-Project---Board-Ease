import 'package:material_ui/material_ui.dart';

import 'maintenance_screen.dart';
import 'owner_payments_screen.dart';
import 'reservations_screen.dart';

/// Owner inbox grouping reservation, maintenance, and payment review queues.
class RequestsHubScreen extends StatelessWidget {
  const RequestsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: <Widget>[
              Tab(text: 'Reservations'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Payments'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ReservationsScreen(),
                MaintenanceScreen(),
                OwnerPaymentsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
