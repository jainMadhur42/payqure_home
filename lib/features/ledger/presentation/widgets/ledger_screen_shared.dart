import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension ServiceEntryStatusLabel on ServiceEntryStatus {
  String get label {
    return switch (this) {
      ServiceEntryStatus.delivered => 'Delivered',
      ServiceEntryStatus.notDelivered => 'Not Delivered',
      ServiceEntryStatus.rateChanged => 'Rate Changed',
      ServiceEntryStatus.noEntry => 'No Entry',
      ServiceEntryStatus.halfDay => 'Half Day',
    };
  }
}

String dateLabel(int day, String monthKey) {
  final parts = monthKey.split('-');
  final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
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
  final monthIndex = (month - 1).clamp(0, 11).toInt();
  return '$day ${months[monthIndex]}';
}

String fullDateLabel(int day, String monthKey) {
  final parts = monthKey.split('-');
  final year = parts.isNotEmpty ? parts.first : '${DateTime.now().year}';
  return '${dateLabel(day, monthKey)} $year';
}

DateTime monthDate(String monthKey) {
  final parts = monthKey.split('-');
  final year = int.tryParse(parts.first) ?? DateTime.now().year;
  final month = parts.length > 1
      ? int.tryParse(parts[1]) ?? DateTime.now().month
      : DateTime.now().month;
  return DateTime(year, month);
}

String monthKeyForDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

String monthLabelShort(String monthKey) {
  final date = monthDate(monthKey);
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
  return '${months[date.month - 1]} ${date.year}';
}

String formatFullDate(DateTime date) {
  return '${dateLabel(date.day, '${date.year}-${date.month.toString().padLeft(2, '0')}')} ${date.year}';
}

IconData serviceIcon(String icon) {
  return switch (icon) {
    'water' => Icons.water_drop_outlined,
    'person' => Icons.person_pin_circle_outlined,
    'car' => Icons.directions_car_outlined,
    'news' => Icons.newspaper_outlined,
    'custom' => Icons.add_circle_outline,
    _ => Icons.home_repair_service_outlined,
  };
}

String providerName(HouseholdService service) {
  for (final item in service.description.split(' • ')) {
    final separator = item.indexOf(':');
    if (separator == -1) {
      continue;
    }
    final label = item.substring(0, separator).trim().toLowerCase();
    if (label == 'provider') {
      final value = item.substring(separator + 1).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return 'Not added';
}

String entryStatusLabel(HouseholdService service, ServiceEntry entry) {
  if (service.templateType == ServiceTemplateType.attendance) {
    return switch (entry.status) {
      ServiceEntryStatus.delivered => 'Present',
      ServiceEntryStatus.notDelivered => 'Absent',
      ServiceEntryStatus.halfDay => 'Half Day',
      _ => entry.status.label,
    };
  }
  return entry.status.label;
}

class SummaryChip extends StatelessWidget {
  const SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.isEmpty ? label : '$label  $value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, super.key});

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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class SettlementRow extends StatelessWidget {
  const SettlementRow({
    required this.label,
    required this.amountCents,
    this.strong = false,
    super.key,
  });

  final String label;
  final int amountCents;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          Text(
            CurrencyFormatter.rupees(amountCents / 100),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: strong ? AppColors.primary : AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}
