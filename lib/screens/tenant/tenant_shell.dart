import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/tenant_maintenance_provider.dart';
import '../../providers/tenant_payments_provider.dart';
import '../../providers/tenant_reservations_provider.dart';
import '../../providers/tenant_rooms_provider.dart';
import '../../widgets/user_avatar.dart';
import '../shared/account_screen.dart';
import 'browse_rooms_screen.dart';
import 'my_rental_screen.dart';
import 'payments_screen.dart';
import 'tenant_maintenance_screen.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _index = 0;
  late final TenantRoomsProvider _rooms;
  late final TenantReservationsProvider _reservations;
  late final TenantPaymentsProvider _payments;
  late final TenantMaintenanceProvider _maintenance;
  late final List<Widget> _tabs;

  static const List<String> _titles = <String>[
    'Browse rooms',
    'My rental',
    'Payments',
    'Maintenance',
    'Account',
  ];

  @override
  void initState() {
    super.initState();
    _rooms = context.read<TenantRoomsProvider>();
    _reservations = context.read<TenantReservationsProvider>();
    _payments = context.read<TenantPaymentsProvider>();
    _maintenance = context.read<TenantMaintenanceProvider>();
    _tabs = <Widget>[
      const BrowseRoomsScreen(),
      MyRentalScreen(
        onBrowse: () => _select(0),
        onOpenPayments: () => _select(2),
      ),
      TenantPaymentsScreen(onBrowse: () => _select(0)),
      TenantMaintenanceScreen(onBrowse: () => _select(0)),
      const AccountScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      _rooms.watchAll();
      _reservations.watchMine(user.uid);
      _payments.watchMine(user.uid);
      _maintenance.watchMine(user.uid);
    });
  }

  @override
  void dispose() {
    _rooms.stop();
    _reservations.stop();
    _payments.stop();
    _maintenance.stop();
    super.dispose();
  }

  void _select(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Tooltip(
                  message: 'Profile',
                  child: UserAvatar(
                    name: user.name,
                    photoUrl: user.photoUrl,
                    radius: 16,
                    onTap: () => _select(4),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Rental',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build_rounded),
            label: 'Repairs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
