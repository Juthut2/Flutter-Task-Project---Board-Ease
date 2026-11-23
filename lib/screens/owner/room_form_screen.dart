import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/address_selection.dart';
import '../../core/constants.dart';
import '../../models/room.dart';
import '../../providers/rooms_provider.dart';
import '../../services/room_service.dart';
import '../../widgets/psgc_address_fields.dart';
import '../../widgets/room_basics_fields.dart';
import '../../widgets/room_house_fields.dart';
import '../../widgets/room_photo_picker.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key, required this.ownerId, this.room});

  final String ownerId;
  final Room? room;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _amenitiesController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();

  late List<String> _photos;
  late AddressSelection _address;
  bool _saving = false;

  bool get _isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _nameController.text = room?.name ?? '';
    _descriptionController.text = room?.description ?? '';
    _rateController.text = _numberText(room?.monthlyRate ?? 0);
    _depositController.text = _numberText(room?.deposit ?? 0);
    _capacityController.text = '${room?.capacity ?? 1}';
    _amenitiesController.text = room?.amenities.join(', ') ?? '';
    _rulesController.text = room?.rules ?? '';
    _photos = List<String>.of(room?.photos ?? const <String>[]);
    _address = AddressSelection(
      province: room?.province ?? '',
      city: room?.city ?? '',
      barangay: room?.barangay ?? '',
      street: room?.street ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _depositController.dispose();
    _capacityController.dispose();
    _amenitiesController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  String _numberText(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  List<String> _parseAmenities(String value) {
    return value
        .split(RegExp(r'[,\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_address.isComplete) {
      _showError('Select a province, city, barangay, and street address.');
      return;
    }
    final amenities = _parseAmenities(_amenitiesController.text);
    if (amenities.length > AppConstants.maxAmenities) {
      _showError('Add at most ${AppConstants.maxAmenities} amenities.');
      return;
    }

    final existing = widget.room;
    final room = Room(
      id: existing?.id ?? '',
      ownerId: existing?.ownerId ?? widget.ownerId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      monthlyRate: double.parse(
        _rateController.text.trim().replaceAll(',', ''),
      ),
      deposit: double.parse(_depositController.text.trim().replaceAll(',', '')),
      capacity: int.parse(_capacityController.text.trim()),
      amenities: amenities,
      rules: _rulesController.text.trim(),
      photos: List<String>.unmodifiable(_photos),
      status: existing?.status ?? RoomStatus.available,
      province: _address.province,
      city: _address.city,
      barangay: _address.barangay,
      street: _address.street.trim(),
      tenantId: existing?.tenantId,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      final provider = context.read<RoomsProvider>();
      if (existing == null) {
        await provider.createRoom(room);
      } else {
        await provider.updateRoom(room);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on RoomFailure catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not save the room. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit room' : 'Add room')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            RoomBasicsFields(
              nameController: _nameController,
              descriptionController: _descriptionController,
              rateController: _rateController,
              depositController: _depositController,
              capacityController: _capacityController,
            ),
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'Location',
              subtitle: 'Address details from the PSGC directory',
            ),
            const SizedBox(height: 12),
            PsgcAddressFields(
              enabled: !_saving,
              initialProvince: room?.province ?? '',
              initialCity: room?.city ?? '',
              initialBarangay: room?.barangay ?? '',
              initialStreet: room?.street ?? '',
              onChanged: (value) => _address = value,
            ),
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'Photos',
              subtitle: 'Upload clear photos of the room and building',
            ),
            const SizedBox(height: 12),
            RoomPhotoPicker(
              photos: _photos,
              onChanged: (value) => setState(() => _photos = value),
            ),
            const SizedBox(height: 22),
            RoomHouseFields(
              amenitiesController: _amenitiesController,
              rulesController: _rulesController,
            ),
            if (room != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      StatusChip.room(room.status),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Status changes automatically when you approve a '
                          'reservation or mark a room available.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save room'),
            ),
          ],
        ),
      ),
    );
  }
}
