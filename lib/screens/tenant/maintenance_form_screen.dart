import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/tenant_rental.dart';
import '../../core/validators.dart';
import '../../providers/tenant_maintenance_provider.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/photo_upload_field.dart';
import '../../widgets/success_dialog.dart';

/// Form for reporting a maintenance issue for the active rental.
class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key, required this.rental});

  final TenantRental rental;

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _photoUrl;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<TenantMaintenanceProvider>().create(
        roomId: widget.rental.room.id,
        title: _titleController.text,
        description: _descriptionController.text,
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      await SuccessDialog.show(
        context,
        title: 'Request submitted!',
        message:
            'The owner will review your maintenance request and update its '
            'status as work progresses.',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on MaintenanceFailure catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHelpers.showSnackBar(
        context,
        'Could not submit the request. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final room = widget.rental.room;
    return Scaffold(
      appBar: AppBar(title: const Text('New maintenance request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      room.name.isEmpty ? 'Your room' : room.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.fullAddress.isEmpty
                          ? 'Address not set'
                          : room.fullAddress,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: AppConstants.maxTitleLength,
              decoration: const InputDecoration(
                labelText: 'Issue title',
                hintText: 'e.g. Leaking bathroom faucet',
                prefixIcon: Icon(Icons.build_outlined),
              ),
              validator: (value) => Validators.required(
                value,
                field: 'Issue title',
                maxLength: AppConstants.maxTitleLength,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              maxLength: AppConstants.maxDescriptionLength,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the problem and when it started',
                alignLabelWithHint: true,
              ),
              validator: (value) => Validators.required(
                value,
                field: 'Description',
                maxLength: AppConstants.maxDescriptionLength,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Photo (optional)',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            PhotoUploadField(
              url: _photoUrl,
              onChanged: (value) => setState(() => _photoUrl = value),
              emptyLabel: 'Add a photo of the issue (optional)',
            ),
            const SizedBox(height: 16),
            Text(
              'The owner will review your request and update its status as '
              'work progresses.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_busy ? 'Submitting...' : 'Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}
