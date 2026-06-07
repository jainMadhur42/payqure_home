import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/amount_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/month_selector.dart';
import '../widgets/service_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.ensureHomeNotificationsConfigured();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.ensureHomeNotificationsConfigured();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
            onRefresh: controller.refreshSelectedMonth,
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
                        onQuickMark: (status) =>
                            controller.saveQuickEntryForService(
                              service: summary.service,
                              day: _quickLogDay(controller.monthKey),
                              status: status,
                            ),
                        onCustomize: () {
                          controller.selectService(summary.service);
                          controller.selectDayForEdit(
                            _quickLogDay(controller.monthKey),
                            source: EntrySource.calendar,
                          );
                        },
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

  int _quickLogDay(String monthKey) {
    final month = LedgerMonth.parse(monthKey);
    final now = DateTime.now();
    if (month == LedgerMonth.fromDate(now)) {
      return now.day;
    }
    return month.daysInMonth;
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

class HomeServiceCard extends StatefulWidget {
  const HomeServiceCard({
    required this.summary,
    required this.monthLabel,
    required this.onTap,
    required this.onQuickMark,
    required this.onCustomize,
    super.key,
  });

  final HomeServiceSummary summary;
  final String monthLabel;
  final VoidCallback onTap;
  final ValueChanged<ServiceEntryStatus> onQuickMark;
  final VoidCallback onCustomize;

  @override
  State<HomeServiceCard> createState() => _HomeServiceCardState();
}

class _HomeServiceCardState extends State<HomeServiceCard> {
  static const _actionSize = 50.0;
  static const _actionSpacing = AppSpacing.sm;
  double _revealOffset = 0;

  List<_SwipeAction> get _actions {
    final service = widget.summary.service;
    return switch (service.templateType) {
      ServiceTemplateType.attendance => [
        _SwipeAction(
          label: 'P',
          tooltip: 'Present',
          color: AppColors.success,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.delivered),
        ),
        _SwipeAction(
          label: 'A',
          tooltip: 'Absent',
          color: AppColors.danger,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.notDelivered),
        ),
        _SwipeAction(
          label: 'H',
          tooltip: 'Half Day',
          color: AppColors.warning,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.halfDay),
        ),
      ],
      ServiceTemplateType.fixedMonthly => [
        _SwipeAction(
          label: 'D',
          tooltip: 'Delivered',
          color: AppColors.success,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.delivered),
        ),
        _SwipeAction(
          label: 'ND',
          tooltip: 'Not Delivered',
          color: AppColors.danger,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.notDelivered),
        ),
      ],
      _ => [
        _SwipeAction(
          label: 'D',
          tooltip: 'Delivered',
          color: AppColors.success,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.delivered),
        ),
        _SwipeAction(
          label: 'ND',
          tooltip: 'Not Delivered',
          color: AppColors.danger,
          onTap: () => widget.onQuickMark(ServiceEntryStatus.notDelivered),
        ),
        _SwipeAction(
          label: 'C',
          tooltip: 'Customize',
          color: AppColors.primary,
          onTap: widget.onCustomize,
        ),
      ],
    };
  }

  double get _maxReveal =>
      _actions.length * _actionSize + (_actions.length + 1) * _actionSpacing;

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

  void _runAction(_SwipeAction action) {
    HapticFeedback.lightImpact();
    setState(() => _revealOffset = 0);
    action.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final service = summary.service;
    final primaryColor = summary.advanceCents > 0
        ? AppColors.info
        : summary.remainingCents > 0
        ? AppColors.danger
        : summary.statusLabel == 'Paid'
        ? AppColors.success
        : AppColors.danger;
    final revealProgress = _maxReveal == 0
        ? 0.0
        : (_revealOffset.abs() / _maxReveal).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.primarySoft.withValues(alpha: 0.42),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: Transform.scale(
                            scale: 0.62 + revealProgress * 0.38,
                            child: _SwipeActionButton(
                              action: action,
                              onPressed: () => _runAction(action),
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: AppCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _revealOffset != 0
                      ? () => setState(() => _revealOffset = 0)
                      : widget.onTap,
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
                              serviceName: service.name,
                              templateType: service.templateType,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                                    '${widget.monthLabel} · ${service.templateType.label}',
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
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeAction {
  const _SwipeAction({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({required this.action, required this.onPressed});

  final _SwipeAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.tooltip,
      child: SizedBox.square(
        dimension: 50,
        child: Material(
          color: action.color,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: Text(
                action.label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
        color: Theme.of(context).colorScheme.onSurface,
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
