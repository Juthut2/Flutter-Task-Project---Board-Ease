import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/validators.dart';

/// Street address input paired with the PSGC dropdowns.
class PsgcStreetField extends StatelessWidget {
  const PsgcStreetField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.words,
      maxLength: AppConstants.maxStreetLength,
      decoration: const InputDecoration(
        labelText: 'Street address',
        hintText: 'House / building number and street',
        prefixIcon: Icon(Icons.signpost_outlined),
      ),
      validator: (value) => Validators.required(
        value,
        field: 'Street address',
        maxLength: AppConstants.maxStreetLength,
      ),
      onChanged: onChanged,
    );
  }
}
