import 'package:flutter/material.dart';

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
                      (payment) => _PaymentTimelineTile(
                        isLast: payment == entry.value.last,
                        payment: payment,
                        onView: () => _showPaymentDetails(context, payment),
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

  void _showPaymentDetails(BuildContext context, PaymentTransaction payment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CurrencyFormatter.rupees(payment.amountCents / 100),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${payment.mode.label} · ${fullDateLabel(payment.paymentDate.day, payment.monthKey)}',
              ),
              if (payment.note.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(payment.note),
              ],
              if (payment.pendingSync) ...[
                const SizedBox(height: AppSpacing.md),
                const StatusPill(label: 'Pending Sync'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context) {
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

class _PaymentTimelineTile extends StatelessWidget {
  const _PaymentTimelineTile({
    required this.isLast,
    required this.payment,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isLast;
  final PaymentTransaction payment;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _modeColor(payment.mode).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: _modeColor(payment.mode),
                size: 15,
              ),
            ),
            if (!isLast) Container(width: 2, height: 42, color: AppColors.line),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onView,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullDateLabel(
                              payment.paymentDate.day,
                              payment.monthKey,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment.mode.label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (payment.pendingSync)
                            Text(
                              'Pending sync',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.warning),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        onView();
                      case 'edit':
                        onEdit();
                      case 'delete':
                        _confirmDelete(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'view', child: Text('View')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                SizedBox(
                  width: 84,
                  child: Text(
                    CurrencyFormatter.rupees(payment.amountCents / 100),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

Color _templateAccent(ServiceTemplateType type) {
  return switch (type) {
    ServiceTemplateType.quantity => AppColors.success,
    ServiceTemplateType.attendance => AppColors.warning,
    ServiceTemplateType.fixedMonthly => AppColors.info,
    ServiceTemplateType.custom => AppColors.primary,
  };
}

Color _modeColor(PaymentMode mode) {
  return switch (mode) {
    PaymentMode.cash => AppColors.success,
    PaymentMode.upi => AppColors.primary,
    PaymentMode.other => AppColors.warning,
  };
}
