import 'package:material_ui/material_ui.dart';

import '../core/helpers.dart';
import '../models/app_user.dart';

/// Compact tenant identity card shown on the room detail screen.
class TenantSummaryCard extends StatelessWidget {
  const TenantSummaryCard({super.key, required this.tenant});

  final AppUser tenant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            AppHelpers.initials(tenant.name),
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(tenant.name),
        subtitle: Text(
          tenant.phone.isEmpty
              ? tenant.email
              : '${tenant.email}\n${tenant.phone}',
        ),
        isThreeLine: tenant.phone.isNotEmpty,
      ),
    );
  }
}
