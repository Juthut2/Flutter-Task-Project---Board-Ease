import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/payments_provider.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tenants_provider.dart';
import '../shared/account_screen.dart';
import 'owner_dashboard_screen.dart';
import 'reservations_screen.dart';
import 'rooms_screen.dart';
import 'tenants_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;
  late final RoomsProvider _rooms;
  late final ReservationsProvider _reservations;
  late final PaymentsProvider _payments;
  late final TenantsProvider _tenants;
  late final List<Widget> _tabs;

  static const List<String> _titles = <String>[
    'Dashboard',
    'Rooms',
    'Reservation requests',
    'Tenants',
    'Account',
  ];

  @override
  void initState() {
    super.initState();
    _rooms = context.read<RoomsProvider>();
    _reservations = context.read<ReservationsProvider>();
    _payments = context.read<PaymentsProvider>();
    _tenants = context.read<TenantsProvider>();
    _tabs = <Widget>[
      OwnerDashboardScreen(
        onOpenRooms: () => _select(1),
        onOpenReservations: () => _select(2),
      ),
      const RoomsScreen(),
      const ReservationsScreen(),
      const TenantsScreen(),
      const AccountScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      _rooms.watchOwnerRooms(user.uid);
      _reservations.watchAll();
      _payments.watchAll();
      _tenants.watchTenants();
    });
  }

  @override
  void dispose() {
    _rooms.stop();
    _reservations.stop();
    _payments.stop();
    _tenants.stop();
    super.dispose();
  }

  void _select(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomsProvider>().rooms;
    final pending = context.watch<ReservationsProvider>().pendingCount(rooms);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work_rounded),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: pending,
              isLabelVisible: pending > 0,
              child: const Icon(Icons.event_available_outlined),
            ),
            selectedIcon: Badge.count(
              count: pending,
              isLabelVisible: pending > 0,
              child: const Icon(Icons.event_available_rounded),
            ),
            label: 'Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Tenants',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
