import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/service_icon.dart';

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
