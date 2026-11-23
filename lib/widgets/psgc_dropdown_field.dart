import 'package:material_ui/material_ui.dart';

import '../services/psgc_service.dart';

/// Reusable PSGC dropdown that keeps the selected code and loading hint.
class PsgcDropdownField extends StatelessWidget {
  const PsgcDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final String hint;
  final List<PsgcOption> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      hint: Text(hint),
      items: items
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.code,
              child: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}
