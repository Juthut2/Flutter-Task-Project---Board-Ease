import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/helpers.dart';
import '../core/validators.dart';

/// Shared gender dropdown and birthday picker for registration and editing.
class ProfileDetailsFields extends StatelessWidget {
  const ProfileDetailsFields({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.birthday,
    required this.onBirthdayChanged,
    this.enabled = true,
  });

  final String? gender;
  final ValueChanged<String> onGenderChanged;
  final DateTime? birthday;
  final ValueChanged<DateTime> onBirthdayChanged;
  final bool enabled;

  Future<void> _pickBirthday(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final now = DateTime.now();
    final latest = DateTime(now.year, now.month, now.day);
    final earliest = DateTime(1900);
    var initial = birthday ?? DateTime(now.year - AppConstants.minimumAge);
    if (initial.isBefore(earliest)) initial = earliest;
    if (initial.isAfter(latest)) initial = latest;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: latest,
      helpText: 'Select your birthday',
    );
    if (picked == null) return;
    field.didChange(picked);
    onBirthdayChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: gender,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          items: AppConstants.genderOptions.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onGenderChanged(value);
                }
              : null,
          validator: (value) {
            if (value == null ||
                !AppConstants.genderOptions.containsKey(value)) {
              return 'Gender is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        FormField<DateTime>(
          initialValue: birthday,
          validator: Validators.birthday,
          builder: (field) => InkWell(
            onTap: enabled ? () => _pickBirthday(context, field) : null,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              isEmpty: birthday == null,
              decoration: InputDecoration(
                labelText: 'Birthday',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: const Icon(Icons.calendar_today_rounded),
                errorText: field.errorText,
              ),
              child: Text(
                birthday == null
                    ? 'Select your birthday'
                    : AppHelpers.formatDate(birthday),
                style: birthday == null
                    ? TextStyle(color: scheme.onSurfaceVariant)
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You must be at least ${AppConstants.minimumAge} years old.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
