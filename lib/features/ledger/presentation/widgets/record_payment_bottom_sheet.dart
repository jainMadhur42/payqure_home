import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/payment_settlement_preview.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_screen_shared.dart';

class RecordPaymentBottomSheet extends StatefulWidget {
  const RecordPaymentBottomSheet({
    required this.controller,
    required this.service,
    this.payment,
    this.returnRoute,
    this.source = 'payment_history',
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;
  final PaymentTransaction? payment;
  final LedgerRoute? returnRoute;
  final String source;

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
  Timer? _previewTimer;
  late Future<PaymentSettlementPreview> _previewFuture;

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
    _previewFuture = _loadPreview();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return FutureBuilder<PaymentSettlementPreview>(
      future: _previewFuture,
      builder: (context, snapshot) {
        final preview = snapshot.data;
        final remaining = preview?.totalDueCents ?? 0;
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
                      preview == null
                          ? 'Loading outstanding balance...'
                          : _dueLabel(preview),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                                  _schedulePreview();
                                },
                              ),
                        errorText: _amountError,
                      ),
                      onChanged: (_) => _schedulePreview(),
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
                              _paymentHelperText(preview),
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
                    if (preview != null && preview.months.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SettlementPreviewCard(preview: preview),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: preview == null ? null : _save,
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

  Future<PaymentSettlementPreview> _loadPreview() {
    return widget.controller.loadPaymentSettlementPreview(
      service: widget.service,
      paymentCents: _enteredAmountCents,
    );
  }

  int get _enteredAmountCents =>
      ((double.tryParse(_amountController.text.trim()) ?? 0) * 100).round();

  void _schedulePreview() {
    _previewTimer?.cancel();
    setState(() {});
    _previewTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      setState(() => _previewFuture = _loadPreview());
    });
  }

  String _dueLabel(PaymentSettlementPreview preview) {
    final labels = preview.months
        .map((month) => monthLabelShort(month.monthKey))
        .toList();
    if (labels.isEmpty) {
      return 'No pending amount is due.';
    }
    final months = labels.length == 1
        ? labels.first
        : labels.length == 2
        ? '${labels.first} and ${labels.last}'
        : '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
    return 'For $months, ${CurrencyFormatter.rupees(preview.totalDueCents / 100)} is due.';
  }

  String _paymentHelperText(PaymentSettlementPreview? preview) {
    final entered =
        ((double.tryParse(_amountController.text.trim()) ?? 0) * 100).round();
    if (entered <= 0) {
      return 'Enter a custom payment amount to preview its settlement.';
    }
    if (preview == null) {
      return 'Calculating settlement...';
    }
    if (preview.remainingDueCents > 0) {
      return '${CurrencyFormatter.rupees(preview.remainingDueCents / 100)} will remain due after settling the oldest months first.';
    }
    if (preview.advanceCents == 0) {
      return 'All pending months will be marked paid.';
    }
    return '${CurrencyFormatter.rupees(preview.advanceCents / 100)} will be added as advance.';
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
        source: widget.source,
        returnRoute: widget.returnRoute ?? LedgerRoute.calendar,
      );
    } else {
      await widget.controller.updatePayment(
        payment: payment,
        amountCents: (amount * 100).round(),
        paymentDate: _paymentDate,
        mode: _mode,
        note: _noteController.text.trim(),
        service: widget.service,
        source: widget.source,
        returnRoute: widget.returnRoute ?? LedgerRoute.paymentHistory,
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

class _SettlementPreviewCard extends StatelessWidget {
  const _SettlementPreviewCard({required this.preview});

  final PaymentSettlementPreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settlement details',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...preview.months.map(
            (month) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      monthLabelShort(month.monthKey),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _allocationLabel(month),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (preview.advanceCents > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Advance balance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.rupees(preview.advanceCents / 100),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _allocationLabel(PaymentMonthAllocation month) {
    if (preview.paymentCents <= 0) {
      return 'Due ${CurrencyFormatter.rupees(month.dueBeforePaymentCents / 100)}';
    }
    if (month.allocatedCents == 0) {
      return 'Still due ${CurrencyFormatter.rupees(month.dueBeforePaymentCents / 100)}';
    }
    if (month.remainingCents == 0) {
      return 'Settled ${CurrencyFormatter.rupees(month.allocatedCents / 100)}';
    }
    return '${CurrencyFormatter.rupees(month.allocatedCents / 100)} paid · ${CurrencyFormatter.rupees(month.remainingCents / 100)} left';
  }
}
