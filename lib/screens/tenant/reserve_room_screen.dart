import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../models/room.dart';
import '../../providers/tenant_reservations_provider.dart';
import '../../services/reservation_service.dart';
import '../../widgets/success_dialog.dart';

/// Move-in date form that creates a pending reservation.
class ReserveRoomScreen extends StatefulWidget {
  const ReserveRoomScreen({super.key, required this.room});

  final Room room;

  @override
  State<ReserveRoomScreen> createState() => _ReserveRoomScreenState();
}

class _ReserveRoomScreenState extends State<ReserveRoomScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _moveInDate;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = DateTime(now.year, now.month + 1);
    _moveInDate = initial;
    _dateController.text = AppHelpers.formatDate(initial);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _moveInDate = picked;
      _dateController.text = AppHelpers.formatDate(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final moveInDate = _moveInDate;
    if (moveInDate == null) return;
    setState(() => _busy = true);
    try {
      await context.read<TenantReservationsProvider>().create(
        roomId: widget.room.id,
        moveInDate: moveInDate,
      );
      if (!mounted) return;
      await SuccessDialog.show(
        context,
        title: 'Request sent!',
        message:
            'The owner will review your reservation. You can follow its '
            'status under My rental.',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ReservationFailure catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHelpers.showSnackBar(
        context,
        'Could not send your request. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(title: const Text('Reserve room')),
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
                      room.name.isEmpty ? 'Untitled room' : room.name,
                      style: textTheme.titleLarge?.copyWith(
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
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Summary(
                            label: 'Monthly rent',
                            value: AppHelpers.formatCurrency(room.monthlyRate),
                          ),
                        ),
                        Expanded(
                          child: _Summary(
                            label: 'Deposit',
                            value: AppHelpers.formatCurrency(room.deposit),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _busy ? null : _pickDate,
              decoration: const InputDecoration(
                labelText: 'Preferred move-in date',
                prefixIcon: Icon(Icons.event_outlined),
                suffixIcon: Icon(Icons.calendar_month_rounded),
              ),
              validator: (_) {
                if (_moveInDate == null) return 'Choose a move-in date';
                final today = DateTime.now();
                final earliest = DateTime(today.year, today.month, today.day);
                if (_moveInDate!.isBefore(earliest)) {
                  return 'Move-in date cannot be in the past';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'This sends a request to the owner. Your room is only confirmed '
              'after approval, and no payment is required yet.',
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
              label: Text(_busy ? 'Sending request...' : 'Send request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
