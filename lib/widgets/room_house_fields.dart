import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import 'section_header.dart';

/// Optional amenities and house rules fields for a room form.
class RoomHouseFields extends StatelessWidget {
  const RoomHouseFields({
    super.key,
    required this.amenitiesController,
    required this.rulesController,
  });

  final TextEditingController amenitiesController;
  final TextEditingController rulesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'House details',
          subtitle: 'Optional amenities and house rules',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: amenitiesController,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Amenities',
            hintText: 'Wi-Fi, aircon, own CR, study desk',
            helperText: 'Separate each amenity with a comma.',
            prefixIcon: Icon(Icons.checklist_rounded),
          ),
          validator: (value) => Validators.optionalText(value, maxLength: 500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: rulesController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          maxLength: AppConstants.maxRulesLength,
          decoration: const InputDecoration(
            labelText: 'House rules',
            hintText: 'Curfew, visitors, smoking, and payment rules',
            alignLabelWithHint: true,
          ),
          validator: (value) => Validators.optionalText(
            value,
            maxLength: AppConstants.maxRulesLength,
          ),
        ),
      ],
    );
  }
}
