import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/advance_payment.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_screen_shared.dart';

class AddAdvanceBottomSheet extends StatefulWidget {
  const AddAdvanceBottomSheet({
    required this.controller,
    required this.serviceId,
    required this.serviceName,
    required this.month,
    required this.onSaved,
    this.title = 'Add Advance',
    this.advance,
    super.key,
  });

  final LedgerController controller;
  final String serviceId;
  final String serviceName;
  final String month;
  final VoidCallback onSaved;
  final String title;
  final AdvancePayment? advance;

  @override
  State<AddAdvanceBottomSheet> createState() => _AddAdvanceBottomSheetState();
}

class _AddAdvanceBottomSheetState extends State<AddAdvanceBottomSheet> {
  static const _maximumAmountDigits = 7;

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _paymentDate;
  String _paymentMode = 'Cash';
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final advance = widget.advance;
    _amountController = TextEditingController(
      text: advance == null ? '500' : _formatAmount(advance.amountCents / 100),
    );
    _noteController = TextEditingController(
      text: _noteWithoutPaymentMode(advance?.note ?? ''),
    );
    _paymentDate = advance?.paidOn ?? DateTime.now();
    _paymentMode = _paymentModeFromNote(advance?.note ?? '');
  }

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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.serviceName} · ${widget.month}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${CurrencyFormatter.symbol} ',
                  errorText: _amountError,
                ),
                onChanged: _validateAmountLength,
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
                  child: Text(
                    widget.advance == null ? 'Save Advance' : 'Update Advance',
                  ),
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
    final amountText = _amountController.text.trim();
    if (amountText.length > _maximumAmountDigits) {
      setState(() {
        _amountError = 'More than 7 digits are not allowed';
      });
      return;
    }
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      setState(() => _amountError = 'Enter an amount greater than 0');
      return;
    }
    setState(() => _amountError = null);
    final note = _noteController.text.trim();
    final savedNote = [
      if (note.isNotEmpty) note,
      'Payment mode: $_paymentMode',
    ].join(' · ');
    final advance = widget.advance;
    if (advance == null) {
      await widget.controller.saveAdvance(
        amountCents: (amount * 100).round(),
        paidOn: _paymentDate,
        note: savedNote,
      );
    } else {
      await widget.controller.updateAdvance(
        advance: advance,
        amountCents: (amount * 100).round(),
        paidOn: _paymentDate,
        note: savedNote,
      );
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    widget.onSaved();
  }

  String _formatAmount(double amount) {
    if (amount.truncateToDouble() == amount) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  String _noteWithoutPaymentMode(String note) {
    return note
        .split(' · ')
        .where((part) => !part.startsWith('Payment mode: '))
        .join(' · ');
  }

  String _paymentModeFromNote(String note) {
    for (final part in note.split(' · ')) {
      if (part.startsWith('Payment mode: ')) {
        final mode = part.substring('Payment mode: '.length);
        if (const ['Cash', 'UPI', 'Other'].contains(mode)) {
          return mode;
        }
      }
    }
    return 'Cash';
  }

  void _validateAmountLength(String value) {
    if (value.length > _maximumAmountDigits) {
      final allowedValue = value.substring(0, _maximumAmountDigits);
      _amountController.value = TextEditingValue(
        text: allowedValue,
        selection: TextSelection.collapsed(offset: allowedValue.length),
      );
      setState(() {
        _amountError = 'More than 7 digits are not allowed';
      });
      return;
    }
    if (_amountError != null) {
      setState(() => _amountError = null);
    }
  }
}
