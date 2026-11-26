import 'package:material_ui/material_ui.dart';

import 'profile_view.dart';

/// Full-screen profile route used by banners and app bar shortcuts.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.startInEditMode = false});

  final bool startInEditMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: ProfileView(startInEditMode: startInEditMode)),
    );
  }
}
