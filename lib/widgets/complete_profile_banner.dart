import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Dismissible nudge for accounts that have not added gender and birthday.
class CompleteProfileBanner extends StatefulWidget {
  const CompleteProfileBanner({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<CompleteProfileBanner> createState() => _CompleteProfileBannerState();
}

class _CompleteProfileBannerState extends State<CompleteProfileBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (_dismissed || user == null || user.hasCompleteProfile) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: widget.onComplete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: <Widget>[
              Icon(Icons.badge_outlined, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Complete your profile',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add your gender and birthday to finish your profile.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: () => setState(() => _dismissed = true),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
