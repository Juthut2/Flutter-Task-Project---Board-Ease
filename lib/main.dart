import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'screens/startup_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const BoardEaseApp());
  } catch (_) {
    runApp(
      const MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        home: StartupErrorScreen(),
      ),
    );
  }
}
