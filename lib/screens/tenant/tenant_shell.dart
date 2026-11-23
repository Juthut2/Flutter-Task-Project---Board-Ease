import 'package:material_ui/material_ui.dart';

import '../shared/account_screen.dart';
import '../shared/role_home_screen.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _index = 0;

  static const List<String> _titles = <String>['Tenant home', 'Account'];

  static const List<Widget> _tabs = <Widget>[
    RoleHomeScreen(
      roleLabel: 'Tenant',
      roleMessage:
          'Browse available rooms, reserve your next home, and keep track of '
          'your payments and maintenance requests.',
      roleIcon: Icons.person_outline_rounded,
    ),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
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
