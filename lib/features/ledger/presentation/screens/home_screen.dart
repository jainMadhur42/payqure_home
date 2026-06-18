import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/amount_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/services/calendar_entry_status_resolver.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/month_selector.dart';
import '../widgets/service_contribution_stats.dart';
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
    final profileName = controller.profile?.name.trim().isNotEmpty == true
        ? controller.profile!.name.trim()
        : overview.profile.name.trim();
    final displayName = profileName.isEmpty ? 'User' : profileName;
    return SafeArea(
      child: FutureBuilder<List<HomeServiceSummary>>(
        future: controller.loadHomeServiceSummaries(),
        builder: (context, snapshot) {
          final serviceSummaries = _sortByTodayStatus(
            snapshot.data ?? const <HomeServiceSummary>[],
          );
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HomeProfileButton(
                      name: displayName,
                      onTap: () => controller.goTo(LedgerRoute.profile),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good day',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                HomeHeroSummaryCard(
                  summary: monthlySummary,
                  onQuickLog: overview.services.isNotEmpty
                      ? () {
                          HapticFeedback.selectionClick();
                          controller.openQuickLog(date: DateTime.now());
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (serviceSummaries.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Spending Stats',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (serviceSummaries.length > 3)
                        TextButton(
                          onPressed: () =>
                              controller.goTo(LedgerRoute.contributionStats),
                          child: const Text('View all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ServiceContributionStatsCard(
                    summaries: serviceSummaries,
                    maxItems: 3,
                    compact: true,
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
                        onTap: () => controller.selectService(summary.service),
                        onQuickMark: (status) =>
                            controller.saveQuickEntryForService(
                              service: summary.service,
                              day: _quickLogDay(controller.monthKey),
                              status: status,
                            ),
                        onCustomize: () => controller.customizeEntryForService(
                          service: summary.service,
                          day: _quickLogDay(controller.monthKey),
                        ),
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

  List<HomeServiceSummary> _sortByTodayStatus(
    List<HomeServiceSummary> summaries,
  ) {
    final indexed = summaries.indexed.toList();
    indexed.sort((left, right) {
      final leftRank = _todayEntryStatus(left.$2.service).sortRank;
      final rightRank = _todayEntryStatus(right.$2.service).sortRank;
      final rankComparison = leftRank.compareTo(rightRank);
      if (rankComparison != 0) {
        return rankComparison;
      }
      return left.$1.compareTo(right.$1);
    });
    return indexed.map((item) => item.$2).toList();
  }
}

class _HomeProfileButton extends StatelessWidget {
  const _HomeProfileButton({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
    return Semantics(
      button: true,
      label: 'Open profile',
      child: Tooltip(
        message: 'Profile',
        child: InkWell(
          key: const ValueKey('home-profile-button'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(
              initial,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeHeroSummaryCard extends StatelessWidget {
  const HomeHeroSummaryCard({
    required this.summary,
    this.onQuickLog,
    super.key,
  });

  final HomeMonthlySummary summary;
  final VoidCallback? onQuickLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: _HeroFloatingIconLayer()),
              ),
              Positioned(
                left: -50,
                top: -72,
                child: IgnorePointer(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _HeroSummaryContent(
                  summary: summary,
                  onQuickLog: onQuickLog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFloatingIconLayer extends StatelessWidget {
  const _HeroFloatingIconLayer();

  @override
  Widget build(BuildContext context) {
    final opacity = Theme.of(context).brightness == Brightness.dark
        ? 0.07
        : 0.09;
    return Stack(
      key: const ValueKey('hero-floating-service-icons'),
      children: [
        Positioned(
          right: 24,
          top: 22,
          child: FloatingHeroIcon(
            icon: Icons.local_drink_outlined,
            size: 42,
            opacity: opacity,
            rotation: -0.12,
          ),
        ),
        Positioned(
          right: 88,
          top: 76,
          child: FloatingHeroIcon(
            icon: Icons.water_drop_outlined,
            size: 34,
            opacity: opacity,
            rotation: 0.10,
          ),
        ),
        Positioned(
          right: 22,
          top: 118,
          child: FloatingHeroIcon(
            icon: Icons.local_car_wash_outlined,
            size: 48,
            opacity: opacity,
            rotation: 0.08,
          ),
        ),
        Positioned(
          right: 108,
          bottom: 72,
          child: FloatingHeroIcon(
            icon: Icons.cleaning_services_outlined,
            size: 38,
            opacity: opacity,
            rotation: -0.10,
          ),
        ),
        Positioned(
          right: 28,
          bottom: 68,
          child: FloatingHeroIcon(
            icon: Icons.article_outlined,
            size: 36,
            opacity: opacity,
            rotation: 0.09,
          ),
        ),
      ],
    );
  }
}

class FloatingHeroIcon extends StatelessWidget {
  const FloatingHeroIcon({
    required this.icon,
    required this.size,
    required this.opacity,
    required this.rotation,
    super.key,
  });

  final IconData icon;
  final double size;
  final double opacity;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}

class _HeroSummaryContent extends StatelessWidget {
  const _HeroSummaryContent({required this.summary, this.onQuickLog});

  final HomeMonthlySummary summary;
  final VoidCallback? onQuickLog;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Material(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onQuickLog,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_outlined,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.serviceCount} Active Services',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (onQuickLog != null)
                          Text(
                            'Quick log',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (onQuickLog != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.78),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    required this.onTap,
    required this.onQuickMark,
    required this.onCustomize,
    super.key,
  });

  final HomeServiceSummary summary;
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
    final todayStatus = _todayEntryStatus(service);
    final todayBorderColor = _todayBorderColor(service);
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
              child: Semantics(
                label: '${service.name}. ${todayStatus.semanticLabel}',
                button: true,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: 5,
                            decoration: BoxDecoration(
                              color: todayBorderColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppRadius.lg),
                                bottomLeft: Radius.circular(AppRadius.lg),
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _revealOffset != 0
                            ? () => setState(() => _revealOffset = 0)
                            : widget.onTap,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HomeServiceCardHeader(
                                service: service,
                                summary: summary,
                                primaryColor: primaryColor,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ServiceMetricLine(text: summary.metricLabel),
                              const SizedBox(height: AppSpacing.sm),
                              ServiceStatusChip(label: summary.statusLabel),
                            ],
                          ),
                        ),
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
}

class _HomeServiceCardHeader extends StatelessWidget {
  const _HomeServiceCardHeader({
    required this.service,
    required this.summary,
    required this.primaryColor,
  });

  final HouseholdService service;
  final HomeServiceSummary summary;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TodayEntrySummary(value: _todayEntryLabel(summary)),
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
              CurrencyFormatter.rupees(summary.primaryAmountCents / 100),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayEntrySummary extends StatelessWidget {
  const _TodayEntrySummary({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Entry",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum _TodayEntryStatus {
  pending(AppColors.warning, 'Today entry pending.', 0),
  logged(AppColors.success, 'Today entry logged.', 1),
  inactive(AppColors.muted, 'Today entry not applicable.', 2);

  const _TodayEntryStatus(this.color, this.semanticLabel, this.sortRank);

  final Color color;
  final String semanticLabel;
  final int sortRank;
}

_TodayEntryStatus _todayEntryStatus(HouseholdService service) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDate = const ServiceStartDateResolver().resolve(service);
  if (startDate != null) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (start.isAfter(today)) {
      return _TodayEntryStatus.inactive;
    }
  }
  final todayMonth = LedgerMonth.fromDate(today).key;
  if (service.monthKey != todayMonth) {
    return _TodayEntryStatus.inactive;
  }
  final hasTodayEntry = service.entries.any((entry) => entry.day == today.day);
  return hasTodayEntry ? _TodayEntryStatus.logged : _TodayEntryStatus.pending;
}

String _todayEntryLabel(HomeServiceSummary summary) {
  final service = summary.service;
  if (service.templateType == ServiceTemplateType.fixedMonthly) {
    return summary.usageCents > 0 || summary.payableCents > 0
        ? 'Billed This Month'
        : 'Not Billed';
  }

  final entry = _todayEntry(service);
  if (entry == null || entry.status == ServiceEntryStatus.noEntry) {
    return 'Not Logged';
  }

  if (service.templateType == ServiceTemplateType.attendance) {
    return switch (entry.status) {
      ServiceEntryStatus.delivered => 'Present',
      ServiceEntryStatus.notDelivered => 'Absent',
      ServiceEntryStatus.halfDay => 'Half Day',
      _ => 'Not Logged',
    };
  }

  return switch (entry.status) {
    ServiceEntryStatus.delivered ||
    ServiceEntryStatus.rateChanged => _quantityEntryLabel(entry, service),
    ServiceEntryStatus.notDelivered => 'Not Delivered',
    _ => 'Not Logged',
  };
}

ServiceEntry? _todayEntry(HouseholdService service) {
  final now = DateTime.now();
  final todayMonth = LedgerMonth.fromDate(now).key;
  if (service.monthKey != todayMonth) {
    return null;
  }
  for (final entry in service.entries) {
    if (entry.day == now.day) {
      return entry;
    }
  }
  return null;
}

String _quantityEntryLabel(ServiceEntry entry, HouseholdService service) {
  final unit = entry.unit.trim().isNotEmpty
      ? entry.unit.trim()
      : service.unit.trim();
  final quantity = _formatQuantity(entry.quantity);
  return unit.isEmpty ? quantity : '$quantity $unit';
}

String _formatQuantity(double value) {
  if (value.truncateToDouble() == value) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Side-border accent for today's entry, using the same status → colour logic
/// as the service detail calendar (delivered = green, missed = red,
/// quantity change = amber, no entry = grey).
Color _todayBorderColor(HouseholdService service) {
  if (_todayEntryStatus(service) == _TodayEntryStatus.inactive) {
    return _visualStatusColor(CalendarEntryVisualStatus.noEntry);
  }
  final now = DateTime.now();
  final todayDay = now.day;
  ServiceEntry? todayEntry;
  for (final entry in service.entries) {
    if (entry.day == todayDay) {
      todayEntry = entry;
      break;
    }
  }
  final visual = CalendarEntryStatusResolver.resolve(
    entry: todayEntry,
    configuredQuantity: service.templateType == ServiceTemplateType.quantity
        ? service.defaultQuantity
        : null,
  );
  return _visualStatusColor(visual);
}

Color _visualStatusColor(CalendarEntryVisualStatus status) {
  return switch (status) {
    CalendarEntryVisualStatus.delivered => AppColors.success,
    CalendarEntryVisualStatus.notDelivered => AppColors.danger,
    CalendarEntryVisualStatus.quantityChanged => AppColors.warning,
    CalendarEntryVisualStatus.noEntry => AppColors.muted,
  };
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
