import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/service_chart_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/entities/service_template.dart';
import 'service_icon.dart';

class ServiceContributionStatsCard extends StatelessWidget {
  const ServiceContributionStatsCard({
    required this.summaries,
    this.maxItems,
    this.compact = false,
    super.key,
  });

  final List<HomeServiceSummary> summaries;
  final int? maxItems;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = ServiceContributionStatsData.fromSummaries(summaries);
    final visibleItems = maxItems == null
        ? items
        : items
              .where((item) => item.amountCents > 0)
              .take(maxItems!)
              .toList(growable: false);
    final totalCents = _totalCents(items);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: items.isEmpty || totalCents <= 0
          ? const _EmptyContributionState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 350;
                final chartSize = compact
                    ? (isNarrow ? 116.0 : 132.0)
                    : (isNarrow ? 132.0 : 164.0);
                final chart = ServiceContributionRing(
                  items: items,
                  totalCents: totalCents,
                  size: chartSize,
                );
                final legend = _ContributionLegend(
                  items: visibleItems,
                  totalCents: totalCents,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    SizedBox(width: isNarrow ? AppSpacing.md : AppSpacing.lg),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
    );
  }

  static int _totalCents(List<ServiceContributionItem> items) {
    return items.fold(0, (sum, item) => sum + item.amountCents);
  }
}

class ServiceContributionDetailList extends StatelessWidget {
  const ServiceContributionDetailList({required this.summaries, super.key});

  final List<HomeServiceSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final items = ServiceContributionStatsData.fromSummaries(summaries);
    final totalCents = items.fold(0, (sum, item) => sum + item.amountCents);
    if (items.isEmpty || totalCents <= 0) {
      return const _EmptyContributionState();
    }
    return Column(
      children: [
        ServiceContributionStatsCard(summaries: summaries),
        const SizedBox(height: AppSpacing.lg),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ContributionDetailCard(
              item: item,
              percent: totalCents == 0 ? 0 : item.amountCents / totalCents,
            ),
          ),
        ),
      ],
    );
  }
}

class ServiceContributionRing extends StatelessWidget {
  const ServiceContributionRing({
    required this.items,
    required this.totalCents,
    required this.size,
    super.key,
  });

  final List<ServiceContributionItem> items;
  final int totalCents;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _ContributionRingPainter(
              items: items,
              totalCents: totalCents,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Spent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceContributionStatsData {
  const ServiceContributionStatsData._();

  static List<ServiceContributionItem> fromSummaries(
    List<HomeServiceSummary> summaries,
  ) {
    final colorOrder = [...summaries]
      ..sort((a, b) {
        final idComparison = a.service.id.compareTo(b.service.id);
        return idComparison != 0
            ? idComparison
            : a.service.name.compareTo(b.service.name);
      });
    final colorsByServiceId = <String, Color>{
      for (var index = 0; index < colorOrder.length; index++)
        colorOrder[index].service.id: ServiceChartPalette.colorAt(index),
    };
    final items = summaries.map((summary) {
      final amountCents = math.max(0, summary.usageCents);
      return ServiceContributionItem(
        summary: summary,
        amountCents: amountCents,
        color:
            colorsByServiceId[summary.service.id] ??
            ServiceChartPalette.colorAt(0),
      );
    }).toList();
    items.sort((a, b) {
      final amountComparison = b.amountCents.compareTo(a.amountCents);
      return amountComparison != 0
          ? amountComparison
          : a.summary.service.name.compareTo(b.summary.service.name);
    });
    return items;
  }
}

class ServiceContributionItem {
  const ServiceContributionItem({
    required this.summary,
    required this.amountCents,
    required this.color,
  });

  final HomeServiceSummary summary;
  final int amountCents;
  final Color color;
}

class _ContributionLegend extends StatelessWidget {
  const _ContributionLegend({required this.items, required this.totalCents});

  final List<ServiceContributionItem> items;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: _ContributionLegendRow(
                item: item,
                percent: totalCents == 0 ? 0 : item.amountCents / totalCents,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ContributionLegendRow extends StatelessWidget {
  const _ContributionLegendRow({required this.item, required this.percent});

  final ServiceContributionItem item;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            item.summary.service.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatPercent(percent),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ContributionDetailCard extends StatelessWidget {
  const _ContributionDetailCard({required this.item, required this.percent});

  final ServiceContributionItem item;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ServiceIcon(
            icon: item.summary.service.icon,
            color: item.color,
            serviceName: item.summary.service.name,
            templateType: item.summary.service.templateType,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.summary.service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.summary.service.templateType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPercent(percent),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: item.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                CurrencyFormatter.rupees(item.amountCents / 100),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyContributionState extends StatelessWidget {
  const _EmptyContributionState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No spending yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                'Service spending appears here after charges are logged.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContributionRingPainter extends CustomPainter {
  const _ContributionRingPainter({
    required this.items,
    required this.totalCents,
    required this.backgroundColor,
  });

  final List<ServiceContributionItem> items;
  final int totalCents;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = math.max(12.0, size.shortestSide * 0.08);
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final backgroundPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.35)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, backgroundPaint);

    if (items.isEmpty || totalCents <= 0) {
      return;
    }

    final contributingItems = items
        .where((item) => item.amountCents > 0)
        .toList(growable: false);
    final gap = contributingItems.length <= 1
        ? 0.0
        : math.min(0.08, math.pi / (contributingItems.length * 5));
    var start = -math.pi / 2;
    for (final item in contributingItems) {
      final sweep = (item.amountCents / totalCents) * math.pi * 2;
      final visibleSweep = math.max(0.005, sweep - gap);
      final paint = Paint()
        ..color = item.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, visibleSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ContributionRingPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.totalCents != totalCents ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

String _formatPercent(double value) {
  final percent = value * 100;
  if (percent == 0) return '0%';
  if (percent < 1) return '<1%';
  return '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%';
}
