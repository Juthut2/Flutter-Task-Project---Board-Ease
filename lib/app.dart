import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/payments_provider.dart';
import 'providers/reservations_provider.dart';
import 'providers/rooms_provider.dart';
import 'providers/tenant_maintenance_provider.dart';
import 'providers/tenant_payments_provider.dart';
import 'providers/tenant_reservations_provider.dart';
import 'providers/tenant_rooms_provider.dart';
import 'providers/tenants_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'widgets/session_guard.dart';

class BoardEaseApp extends StatefulWidget {
  const BoardEaseApp({super.key});

  @override
  State<BoardEaseApp> createState() => _BoardEaseAppState();
}

class _BoardEaseAppState extends State<BoardEaseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider<RoomsProvider>(create: (_) => RoomsProvider()),
        ChangeNotifierProvider<ReservationsProvider>(
          create: (_) => ReservationsProvider(),
        ),
        ChangeNotifierProvider<PaymentsProvider>(
          create: (_) => PaymentsProvider(),
        ),
        ChangeNotifierProvider<TenantsProvider>(
          create: (_) => TenantsProvider(),
        ),
        ChangeNotifierProvider<MaintenanceProvider>(
          create: (_) => MaintenanceProvider(),
        ),
        ChangeNotifierProvider<TenantRoomsProvider>(
          create: (_) => TenantRoomsProvider(),
        ),
        ChangeNotifierProvider<TenantReservationsProvider>(
          create: (_) => TenantReservationsProvider(),
        ),
        ChangeNotifierProvider<TenantPaymentsProvider>(
          create: (_) => TenantPaymentsProvider(),
        ),
        ChangeNotifierProvider<TenantMaintenanceProvider>(
          create: (_) => TenantMaintenanceProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        builder: (context, child) => SessionGuard(
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
