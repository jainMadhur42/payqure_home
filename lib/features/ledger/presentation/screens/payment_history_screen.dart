import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/record_payment_bottom_sheet.dart';
import '../widgets/service_icon.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentTransaction>>(
      future: controller.loadSelectedPaymentHistory(),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? const <PaymentTransaction>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (payments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_outlined, color: AppColors.muted),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No payments recorded yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => _showRecordPaymentSheet(context),
                      child: const Text('Record Payment'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final grouped = <String, List<PaymentTransaction>>{};
        for (final payment in payments) {
          grouped.putIfAbsent(payment.monthKey, () => []).add(payment);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  ServiceIcon(
                    icon: service.icon,
                    color: _templateAccent(service.templateType),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Provider: ${providerName(service)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...grouped.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabelShort(entry.key),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...entry.value.map(
                      (payment) => PaymentHistoryCard(
                        service: service,
                        payment: payment,
                        onEdit: () => _showEditPaymentSheet(context, payment),
                        onDelete: () => controller.deletePayment(payment),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'All payments are securely stored and synced across your devices.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRecordPaymentSheet(BuildContext context) {
    controller.trackRecordPaymentStarted(
      service: service,
      source: 'payment_history',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RecordPaymentBottomSheet(controller: controller, service: service),
    );
  }

  void _showEditPaymentSheet(BuildContext context, PaymentTransaction payment) {
    controller.trackRecordPaymentStarted(
      service: service,
      source: 'payment_history',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentBottomSheet(
        controller: controller,
        service: service,
        payment: payment,
      ),
    );
  }
}

class PaymentHistoryCard extends StatefulWidget {
  const PaymentHistoryCard({
    required this.service,
    required this.payment,
    required this.onEdit,
    required this.onDelete,
    this.showServiceName = false,
    super.key,
  });

  final HouseholdService service;
  final PaymentTransaction payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showServiceName;

  @override
  State<PaymentHistoryCard> createState() => _PaymentHistoryCardState();
}

class _PaymentHistoryCardState extends State<PaymentHistoryCard> {
  static const _actionSize = 50.0;
  static const _maxReveal = (_actionSize * 2) + AppSpacing.md;
  double _revealOffset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _revealOffset = (_revealOffset + details.delta.dx).clamp(-_maxReveal, 0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldOpen =
        details.primaryVelocity != null && details.primaryVelocity! < -250 ||
        _revealOffset.abs() > _maxReveal * 0.42;
    setState(() => _revealOffset = shouldOpen ? -_maxReveal : 0);
    if (shouldOpen) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final scheme = Theme.of(context).colorScheme;
    final allocationLines = _allocationLines(payment);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                right: AppSpacing.xs,
                bottom: AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SwipeActionButton(
                      color: AppColors.primary,
                      icon: Icons.edit_outlined,
                      onTap: _editFromSwipe,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _SwipeActionButton(
                      color: AppColors.danger,
                      icon: Icons.delete_outline,
                      onTap: _deleteFromSwipe,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_revealOffset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_revealOffset != 0) {
                  setState(() => _revealOffset = 0);
                }
              },
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ServiceIcon(
                            icon: widget.service.icon,
                            color: widget.service.templateType.color,
                            serviceName: widget.service.name,
                            templateType: widget.service.templateType,
                            size: 46,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyFormatter.rupees(
                                    payment.amountCents / 100,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.showServiceName
                                      ? widget.service.name
                                      : '${payment.mode.label} · ${fullDateLabel(payment.paymentDate.day, monthKeyForDate(payment.paymentDate))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: widget.showServiceName
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant,
                                        fontWeight: widget.showServiceName
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                ),
                                if (widget.showServiceName) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${payment.mode.label} · ${fullDateLabel(payment.paymentDate.day, monthKeyForDate(payment.paymentDate))}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (payment.pendingSync)
                            const StatusPill(label: 'Sync'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Settlement Description',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Applied to oldest pending balance first, then current month. Extra amount becomes advance.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (allocationLines.isEmpty)
                        _SettlementAllocationRow(
                          line: _SettlementLine(
                            icon: Icons.receipt_long_outlined,
                            title: 'Applied to bill',
                            subtitle:
                                'Legacy payment without detailed allocation',
                            amountCents: payment.amountCents,
                            color: AppColors.primary,
                          ),
                          totalCents: payment.amountCents,
                        )
                      else
                        ...allocationLines.map(
                          (line) => _SettlementAllocationRow(
                            line: line,
                            totalCents: payment.amountCents,
                          ),
                        ),
                      if (payment.note.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Note',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                payment.note,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.swipe_left,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Swipe left to edit or delete',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_SettlementLine> _allocationLines(PaymentTransaction payment) {
    return [
      if (payment.previousBalanceAmountCents > 0)
        _SettlementLine(
          icon: Icons.history_outlined,
          title: 'Previous balance',
          subtitle: 'Settled oldest pending month dues',
          amountCents: payment.previousBalanceAmountCents,
          color: AppColors.warning,
        ),
      if (payment.currentMonthAmountCents > 0)
        _SettlementLine(
          icon: Icons.calendar_month_outlined,
          title: 'Current month',
          subtitle: '${monthLabelShort(payment.monthKey)} charges',
          amountCents: payment.currentMonthAmountCents,
          color: AppColors.info,
        ),
      if (payment.advanceAmountCents > 0)
        _SettlementLine(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Advance balance',
          subtitle: 'Extra amount carried forward',
          amountCents: payment.advanceAmountCents,
          color: AppColors.success,
        ),
    ];
  }

  void _editFromSwipe() {
    HapticFeedback.selectionClick();
    setState(() => _revealOffset = 0);
    widget.onEdit();
  }

  void _deleteFromSwipe() {
    HapticFeedback.lightImpact();
    setState(() => _revealOffset = 0);
    _confirmDelete(context);
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: const Text('This will update the settlement for this month.'),
        actions: [
          TextButton(
            onPressed: Navigator.of(dialogContext).pop,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _PaymentHistoryCardState._actionSize,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _SettlementAllocationRow extends StatelessWidget {
  const _SettlementAllocationRow({
    required this.line,
    required this.totalCents,
  });

  final _SettlementLine line;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = totalCents <= 0 ? 0.0 : line.amountCents / totalCents;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: line.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(line.icon, color: line.color, size: 19),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                CurrencyFormatter.rupees(line.amountCents / 100),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 5,
              backgroundColor: line.color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(line.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementLine {
  const _SettlementLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountCents,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int amountCents;
  final Color color;
}

Color _templateAccent(ServiceTemplateType type) {
  return switch (type) {
    ServiceTemplateType.quantity => AppColors.success,
    ServiceTemplateType.attendance => AppColors.warning,
    ServiceTemplateType.fixedMonthly => AppColors.info,
  };
}
