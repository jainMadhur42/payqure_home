import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/amount_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/month_selector.dart';
import '../widgets/service_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final overview = controller.overview!;
    return SafeArea(
      child: FutureBuilder<List<HomeServiceSummary>>(
        future: controller.loadHomeServiceSummaries(),
        builder: (context, snapshot) {
          final serviceSummaries =
              snapshot.data ?? const <HomeServiceSummary>[];
          final monthlySummary = controller.buildHomeMonthlySummary(
            serviceSummaries,
          );
          return RefreshIndicator(
            onRefresh: () async => controller.goTo(controller.route),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                104,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good day, ${overview.profile.name.split(' ').first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Payqure Home',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    MonthSelector(controller: controller),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                HomeHeroSummaryCard(summary: monthlySummary),
                const SizedBox(height: AppSpacing.lg),
                if (overview.services.length > 1) ...[
                  QuickLogHomeAction(
                    serviceCount: overview.services.length,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.openQuickLog(date: DateTime.now());
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (overview.services.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.home_repair_service_outlined,
                          color: AppColors.primary,
                          size: 42,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No services yet',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Add your first household service to start tracking.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (!snapshot.hasData)
                  const HomeServiceListSkeleton()
                else ...[
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...serviceSummaries.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: HomeServiceCard(
                        summary: summary,
                        monthLabel: overview.monthLabel,
                        onTap: () => controller.selectService(summary.service),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class QuickLogHomeAction extends StatelessWidget {
  const QuickLogHomeAction({
    required this.serviceCount,
    required this.onTap,
    super.key,
  });

  final int serviceCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Log Today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Update $serviceCount services in one place',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeroSummaryCard extends StatelessWidget {
  const HomeHeroSummaryCard({required this.summary, super.key});

  final HomeMonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount Due',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(
            amount: summary.totalDueCents / 100,
            large: true,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _HeroMetricItem(
                  label: 'This month Charges',
                  value: CurrencyFormatter.rupees(summary.usageCents / 100),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _HeroMetricItem(
                  label: 'Previous Balance',
                  value: CurrencyFormatter.rupees(
                    summary.previousPendingCents / 100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMetricItem(
                  label: 'Advance balance',
                  value: CurrencyFormatter.rupees(summary.advanceCents / 100),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _HeroMetricItem(
                  label: 'Paid this month',
                  value: CurrencyFormatter.rupees(summary.paidCents / 100),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${summary.serviceCount} Active Services',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricItem extends StatelessWidget {
  const _HeroMetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class HomeServiceCard extends StatelessWidget {
  const HomeServiceCard({
    required this.summary,
    required this.monthLabel,
    required this.onTap,
    super.key,
  });

  final HomeServiceSummary summary;
  final String monthLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final service = summary.service;
    final primaryColor = summary.advanceCents > 0
        ? AppColors.info
        : summary.remainingCents > 0
        ? AppColors.danger
        : AppColors.success;
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceIcon(
                    icon: service.icon,
                    color: service.templateType.color,
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
                          'Provider: ${providerName(service)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                        Text(
                          '$monthLabel · ${service.templateType.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        summary.primaryLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.rupees(
                          summary.primaryAmountCents / 100,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ServiceMetricLine(text: summary.metricLabel),
              const SizedBox(height: AppSpacing.sm),
              ServiceStatusChip(label: summary.statusLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceMetricLine extends StatelessWidget {
  const ServiceMetricLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class ServiceStatusChip extends StatelessWidget {
  const ServiceStatusChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Paid' => AppColors.success,
      'Partially Paid' => AppColors.warning,
      'Overpaid' => AppColors.info,
      'Pending' => AppColors.danger,
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
