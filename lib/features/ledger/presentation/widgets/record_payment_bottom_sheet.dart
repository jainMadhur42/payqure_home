import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/payment_transaction.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_screen_shared.dart';

class RecordPaymentBottomSheet extends StatefulWidget {
  const RecordPaymentBottomSheet({
    required this.controller,
    required this.service,
    this.payment,
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;
  final PaymentTransaction? payment;

  @override
  State<RecordPaymentBottomSheet> createState() =>
      _RecordPaymentBottomSheetState();
}

class _RecordPaymentBottomSheetState extends State<RecordPaymentBottomSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  PaymentMode _mode = PaymentMode.upi;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    if (payment != null) {
      _amountController.text = (payment.amountCents / 100).toStringAsFixed(
        payment.amountCents % 100 == 0 ? 0 : 2,
      );
      _noteController.text = payment.note;
      _paymentDate = payment.paymentDate;
      _mode = payment.mode;
    }
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
    return FutureBuilder<MonthlyBill>(
      future: widget.controller.loadBillForService(widget.service),
      builder: (context, snapshot) {
        final settlement = snapshot.data?.settlement;
        final remaining = settlement?.remainingAmountCents ?? 0;
        final effectiveRemaining =
            remaining + (widget.payment?.amountCents ?? 0);
        if (_amountController.text.isEmpty && remaining > 0) {
          _amountController.text = (remaining / 100).toStringAsFixed(
            remaining % 100 == 0 ? 0 : 2,
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.payment == null
                          ? 'Record Payment'
                          : 'Edit Payment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${widget.service.name}  ·  ${widget.controller.overview?.monthLabel ?? widget.controller.monthKey}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Remaining Due',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.rupees(remaining / 100),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Payment Amount',
                        prefixText: '${CurrencyFormatter.symbol} ',
                        suffixIcon: _amountController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.cancel, size: 18),
                                onPressed: () {
                                  _amountController.clear();
                                  setState(() {});
                                },
                              ),
                        errorText: _amountError,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Payment Mode',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: PaymentMode.values
                          .map(
                            (mode) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: mode == PaymentMode.values.last
                                      ? 0
                                      : AppSpacing.sm,
                                ),
                                child: _PaymentModeChip(
                                  mode: mode,
                                  isSelected: _mode == mode,
                                  onTap: () => setState(() => _mode = mode),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Payment Date',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: _pickPaymentDate,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(_paymentDateLabel)),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note Optional',
                        hintText: 'Add a note',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _paymentHelperText(effectiveRemaining),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.ink.withValues(
                                      alpha: 0.74,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: settlement == null ? null : _save,
                        child: Text(
                          widget.payment == null
                              ? 'Save Payment'
                              : 'Update Payment',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String get _paymentDateLabel {
    return fullDateLabel(_paymentDate.day, monthKeyForDate(_paymentDate));
  }

  String _paymentHelperText(int remainingCents) {
    final entered =
        ((double.tryParse(_amountController.text.trim()) ?? 0) * 100).round();
    if (entered <= 0) {
      return 'Enter the amount paid for this month.';
    }
    if (entered < remainingCents) {
      return '${CurrencyFormatter.rupees((remainingCents - entered) / 100)} will remain due and carry forward.';
    }
    if (entered == remainingCents) {
      return 'This bill will be marked Paid.';
    }
    return '${CurrencyFormatter.rupees((entered - remainingCents) / 100)} will be added as advance.';
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
    final payment = widget.payment;
    if (payment == null) {
      await widget.controller.savePayment(
        amountCents: (amount * 100).round(),
        paymentDate: _paymentDate,
        mode: _mode,
        note: _noteController.text.trim(),
      );
    } else {
      await widget.controller.updatePayment(
        payment: payment,
        amountCents: (amount * 100).round(),
        paymentDate: _paymentDate,
        mode: _mode,
        note: _noteController.text.trim(),
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _PaymentModeChip extends StatelessWidget {
  const _PaymentModeChip({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySoft
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            mode.label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
