import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import 'section_header.dart';

/// Name, description, pricing, and capacity fields for a room form.
class RoomBasicsFields extends StatelessWidget {
  const RoomBasicsFields({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.rateController,
    required this.depositController,
    required this.capacityController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController rateController;
  final TextEditingController depositController;
  final TextEditingController capacityController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Room details',
          subtitle: 'Give tenants a clear picture of the space',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          maxLength: AppConstants.maxNameLength,
          decoration: const InputDecoration(
            labelText: 'Room name',
            hintText: 'e.g. Room 2 - Aircon',
            prefixIcon: Icon(Icons.meeting_room_outlined),
          ),
          validator: (value) => Validators.required(
            value,
            field: 'Room name',
            maxLength: AppConstants.maxNameLength,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: descriptionController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 4,
          maxLength: AppConstants.maxDescriptionLength,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the room, furnishings, and nearby landmarks',
            alignLabelWithHint: true,
          ),
          validator: (value) => Validators.required(
            value,
            field: 'Description',
            maxLength: AppConstants.maxDescriptionLength,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly rate',
                  prefixText: '\u20B1 ',
                ),
                validator: (value) =>
                    Validators.amount(value, field: 'Monthly rate'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: depositController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Deposit',
                  prefixText: '\u20B1 ',
                ),
                validator: (value) =>
                    Validators.nonNegativeAmount(value, field: 'Deposit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: capacityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Capacity',
            hintText: 'Number of people',
            prefixIcon: Icon(Icons.people_outline_rounded),
          ),
          validator: (value) =>
              Validators.positiveInt(value, field: 'Capacity'),
        ),
      ],
    );
  }
}
