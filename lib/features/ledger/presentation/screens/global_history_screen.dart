import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/record_payment_bottom_sheet.dart';
import '../widgets/service_icon.dart';
import 'payment_history_screen.dart';

class GlobalHistoryScreen extends StatelessWidget {
  const GlobalHistoryScreen({
    required this.controller,
    required this.type,
    super.key,
  });

  final LedgerController controller;
  final ServiceHistoryType type;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceHistoryItem>>(
      future: type == ServiceHistoryType.payment
          ? controller.loadGlobalPaymentHistory()
          : controller.loadGlobalAdvanceHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <ServiceHistoryItem>[];
        if (items.isEmpty) {
          return _HistoryEmptyState(type: type);
        }
        if (type == ServiceHistoryType.payment) {
          return _GlobalPaymentHistoryList(
            controller: controller,
            items: items,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) =>
              ServiceHistoryCard(item: items[index]),
        );
      },
    );
  }
}

class _GlobalPaymentHistoryList extends StatelessWidget {
  const _GlobalPaymentHistoryList({
    required this.controller,
    required this.items,
  });

  final LedgerController controller;
  final List<ServiceHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ServiceHistoryItem>>{};
    for (final item in items) {
      final payment = item.payment;
      final monthKey = payment?.monthKey ?? monthKeyForDate(item.date);
      grouped.putIfAbsent(monthKey, () => []).add(item);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        ...grouped.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabelShort(entry.key),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...entry.value.map((item) {
                  final payment = item.payment;
                  if (payment == null) {
                    return ServiceHistoryCard(item: item);
                  }
                  return PaymentHistoryCard(
                    service: item.service,
                    payment: payment,
                    showServiceName: true,
                    onEdit: () =>
                        _showEditPaymentSheet(context, serviceItem: item),
                    onDelete: () => controller.deletePayment(
                      payment,
                      service: item.service,
                      source: 'global_payment_history',
                      returnRoute: LedgerRoute.globalPaymentHistory,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const _SecurePaymentsCard(),
      ],
    );
  }

  void _showEditPaymentSheet(
    BuildContext context, {
    required ServiceHistoryItem serviceItem,
  }) {
    final payment = serviceItem.payment;
    if (payment == null) {
      return;
    }
    controller.trackRecordPaymentStarted(
      service: serviceItem.service,
      source: 'global_payment_history',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentBottomSheet(
        controller: controller,
        service: serviceItem.service,
        payment: payment,
        source: 'global_payment_history',
        returnRoute: LedgerRoute.globalPaymentHistory,
      ),
    );
  }
}

class _SecurePaymentsCard extends StatelessWidget {
  const _SecurePaymentsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'All payments are securely stored and synced across your devices.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceHistoryCard extends StatelessWidget {
  const ServiceHistoryCard({required this.item, super.key});

  final ServiceHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceIcon(
            icon: service.icon,
            color: service.templateType.color,
            serviceName: service.name,
            templateType: service.templateType,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      CurrencyFormatter.rupees(item.amountCents / 100),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.modeLabel} · ${_dateLabel(item.date)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (item.pendingSync) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pending sync',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.type});

  final ServiceHistoryType type;

  @override
  Widget build(BuildContext context) {
    final isPayment = type == ServiceHistoryType.payment;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPayment
                  ? Icons.account_balance_wallet_outlined
                  : Icons.savings_outlined,
              color: AppColors.primary,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isPayment ? 'No payments yet' : 'No advances yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
