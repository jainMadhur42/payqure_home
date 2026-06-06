import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_screen_shared.dart';

class AddAdvanceBottomSheet extends StatefulWidget {
  const AddAdvanceBottomSheet({
    required this.controller,
    required this.serviceId,
    required this.serviceName,
    required this.month,
    required this.onSaved,
    super.key,
  });

  final LedgerController controller;
  final String serviceId;
  final String serviceName;
  final String month;
  final VoidCallback onSaved;

  @override
  State<AddAdvanceBottomSheet> createState() => _AddAdvanceBottomSheetState();
}

class _AddAdvanceBottomSheetState extends State<AddAdvanceBottomSheet> {
  final _amountController = TextEditingController(text: '500');
  final _noteController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'Cash';
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Advance',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.serviceName} · ${widget.month}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${CurrencyFormatter.symbol} ',
                  errorText: _amountError,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _pickPaymentDate,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(
                  fullDateLabel(
                    _paymentDate.day,
                    monthKeyForDate(_paymentDate),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Payment Mode',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: ['Cash', 'UPI', 'Other']
                    .map(
                      (mode) => ChoiceChip(
                        label: Text(mode),
                        selected: _paymentMode == mode,
                        onSelected: (_) => setState(() => _paymentMode = mode),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note Optional',
                  hintText: 'Paid in advance',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save Advance'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _amountError = 'Enter an amount greater than 0');
      return;
    }
    setState(() => _amountError = null);
    final note = _noteController.text.trim();
    await widget.controller.saveAdvance(
      amountCents: (amount * 100).round(),
      paidOn: _paymentDate,
      note: [
        if (note.isNotEmpty) note,
        'Payment mode: $_paymentMode',
      ].join(' · '),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    widget.onSaved();
  }
}
