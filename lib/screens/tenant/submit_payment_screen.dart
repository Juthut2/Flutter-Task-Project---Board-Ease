import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/tenant_rental.dart';
import '../../core/validators.dart';
import '../../models/payment.dart';
import '../../providers/tenant_payments_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/photo_upload_field.dart';
import '../../widgets/success_dialog.dart';

/// Form for submitting a proof of payment for owner verification.
class SubmitPaymentScreen extends StatefulWidget {
  const SubmitPaymentScreen({super.key, required this.rental});

  final TenantRental rental;

  @override
  State<SubmitPaymentScreen> createState() => _SubmitPaymentScreenState();
}

class _SubmitPaymentScreenState extends State<SubmitPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final List<String> _months;
  late String _month;
  String? _proofUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = <String>[
      for (var offset = 0; offset < 3; offset++)
        AppHelpers.monthKey(DateTime(now.year, now.month + offset)),
    ];
    _month = _months.contains(widget.rental.dueMonth)
        ? widget.rental.dueMonth
        : _months.first;
    _amountController = TextEditingController(
      text: widget.rental.room.monthlyRate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final proofUrl = _proofUrl;
    if (proofUrl == null || proofUrl.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Upload a proof of payment image first.',
        isError: true,
      );
      return;
    }

    final payments = context.read<TenantPaymentsProvider>().payments;
    final existing = payments.where(
      (payment) =>
          payment.roomId == widget.rental.room.id && payment.month == _month,
    );
    if (existing.any((payment) => payment.status == PaymentStatus.verified)) {
      AppHelpers.showSnackBar(
        context,
        'This month is already marked as paid.',
        isError: true,
      );
      return;
    }
    if (existing.any((payment) => payment.status == PaymentStatus.pending)) {
      AppHelpers.showSnackBar(
        context,
        'A payment for this month is already under review.',
        isError: true,
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null) return;

    setState(() => _busy = true);
    try {
      await context.read<TenantPaymentsProvider>().submit(
        roomId: widget.rental.room.id,
        amount: amount,
        month: _month,
        proofUrl: proofUrl,
      );
      if (!mounted) return;
      await SuccessDialog.show(
        context,
        title: 'Payment submitted!',
        message:
            'Your proof is waiting for owner verification. Keep your receipt '
            'until the payment shows as verified.',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PaymentFailure catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHelpers.showSnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHelpers.showSnackBar(
        context,
        'Could not submit your payment. Please try again.',
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
      appBar: AppBar(title: const Text('Submit payment')),
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
                      'Monthly rent ${AppHelpers.formatCurrency(room.monthlyRate)}',
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
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                prefixText: '\u20B1 ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) => Validators.amount(value, field: 'Amount'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _month,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Rent month',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: _months
                  .map(
                    (month) => DropdownMenuItem<String>(
                      value: month,
                      child: Text(AppHelpers.formatMonth(month)),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _month = value);
                    },
            ),
            const SizedBox(height: 20),
            Text(
              'Proof of payment',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            PhotoUploadField(
              url: _proofUrl,
              onChanged: (value) => setState(() => _proofUrl = value),
              emptyLabel: 'Upload proof of payment',
            ),
            const SizedBox(height: 16),
            Text(
              'The owner verifies every payment. Keep your receipt until it '
              'shows as verified in your payment history.',
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
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_busy ? 'Submitting...' : 'Submit payment'),
            ),
          ],
        ),
      ),
    );
  }
}
