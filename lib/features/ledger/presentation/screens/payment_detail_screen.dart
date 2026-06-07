import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/service_template.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/service_icon.dart';

class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({
    required this.service,
    required this.payment,
    super.key,
  });

  final HouseholdService service;
  final PaymentTransaction payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allocationLines = _allocationLines();
    final allocatedCents = allocationLines.fold<int>(
      0,
      (sum, line) => sum + line.amountCents,
    );
    final unallocatedCents = (payment.amountCents - allocatedCents).clamp(
      0,
      payment.amountCents,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceIcon(
                    icon: service.icon,
                    color: service.templateType.color,
                    serviceName: service.name,
                    templateType: service.templateType,
                    size: 48,
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
                        const SizedBox(height: 2),
                        Text(
                          '${payment.mode.label} · ${fullDateLabel(payment.paymentDate.day, monthKeyForDate(payment.paymentDate))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Payment Amount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                CurrencyFormatter.rupees(payment.amountCents / 100),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (payment.pendingSync) ...[
                const SizedBox(height: AppSpacing.md),
                const StatusPill(label: 'Pending Sync'),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settlement Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This payment is applied to pending previous balances first, then current month charges. Any extra amount becomes advance balance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (allocationLines.isEmpty && unallocatedCents == 0)
                Text(
                  'No settlement split was recorded for this payment.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else ...[
                ...allocationLines.map(
                  (line) => _SettlementAllocationRow(
                    line: line,
                    totalCents: payment.amountCents,
                  ),
                ),
                if (unallocatedCents > 0)
                  _SettlementAllocationRow(
                    line: _SettlementLine(
                      icon: Icons.receipt_long_outlined,
                      title: 'Applied to bill',
                      subtitle: 'Legacy payment without detailed allocation',
                      amountCents: unallocatedCents,
                      color: AppColors.primary,
                    ),
                    totalCents: payment.amountCents,
                  ),
              ],
            ],
          ),
        ),
        if (payment.note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  payment.note,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<_SettlementLine> _allocationLines() {
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: line.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(line.icon, color: line.color, size: 20),
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
              const SizedBox(width: AppSpacing.md),
              Text(
                CurrencyFormatter.rupees(line.amountCents / 100),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: line.color,
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
