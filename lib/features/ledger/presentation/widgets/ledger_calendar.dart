import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/services/calendar_entry_status_resolver.dart';

class LedgerCalendar extends StatelessWidget {
  const LedgerCalendar({
    required this.entries,
    required this.monthKey,
    required this.onDaySelected,
    this.configuredQuantity,
    this.serviceStartDate,
    this.onBlockedDaySelected,
    required this.selectedDay,
    super.key,
  });

  final List<ServiceEntry> entries;
  final String monthKey;
  final int selectedDay;
  final double? configuredQuantity;
  final ValueChanged<int> onDaySelected;
  final DateTime? serviceStartDate;
  final ValueChanged<DateTime>? onBlockedDaySelected;

  @override
  Widget build(BuildContext context) {
    final monthDate = LedgerMonth.parse(monthKey).firstDay;
    final leadingBlanks = List<Widget>.filled(
      monthDate.weekday % 7,
      const SizedBox.shrink(),
    );
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final entryByDay = {for (final entry in entries) entry.day: entry};
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.xs;
        final cellSize = (constraints.maxWidth - spacing * 6) / 7;
        final dayCells = List<Widget>.generate(daysInMonth, (index) {
          final day = index + 1;
          final selected = day == selectedDay;
          final date = DateTime(monthDate.year, monthDate.month, day);
          final isBlocked =
              serviceStartDate != null &&
              date.isBefore(
                DateTime(
                  serviceStartDate!.year,
                  serviceStartDate!.month,
                  serviceStartDate!.day,
                ),
              );
          final isFuture = date.isAfter(todayDate);
          final isInteractionBlocked = isBlocked || isFuture;
          final entry = entryByDay[day];
          final status = isFuture
              ? CalendarEntryVisualStatus.noEntry
              : CalendarEntryStatusResolver.resolve(
                  entry: entry,
                  configuredQuantity: configuredQuantity,
                );
          return SizedBox.square(
            dimension: cellSize.clamp(44.0, 58.0),
            child: CalendarDayCell(
              key: ValueKey('calendar-day-${date.toIso8601String()}'),
              date: date,
              status: status,
              isSelected: selected && !isInteractionBlocked,
              isToday: date == todayDate,
              isBlocked: isInteractionBlocked,
              onTap: () {
                if (isInteractionBlocked) {
                  onBlockedDaySelected?.call(date);
                  return;
                }
                HapticFeedback.selectionClick();
                onDaySelected(day);
              },
            ),
          );
        });

        return Column(
          children: [
            Row(
              children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1,
              children: [...leadingBlanks, ...dayCells],
            ),
          ],
        );
      },
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.status,
    required this.isSelected,
    required this.isToday,
    this.isBlocked = false,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final CalendarEntryVisualStatus status;
  final bool isSelected;
  final bool isToday;
  final bool isBlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _entryColors(context, status);
    final hasLoggedStatus =
        status != CalendarEntryVisualStatus.noEntry && !isBlocked;
    final showSelectedCircle = isSelected && !isBlocked;
    final textColor = showSelectedCircle
        ? colorScheme.onPrimary
        : isBlocked
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.55)
        : isSelected || isToday
        ? colorScheme.primary
        : colors.foreground;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: showSelectedCircle
              ? colorScheme.primary
              : hasLoggedStatus
              ? colors.background
              : Colors.transparent,
          shape: BoxShape.circle,
          border: hasLoggedStatus
              ? Border.all(
                  color: showSelectedCircle
                      ? colorScheme.primary
                      : colors.border,
                )
              : showSelectedCircle
              ? Border.all(color: colorScheme.primary)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (showSelectedCircle) ...[
              const SizedBox(height: 2),
              Container(
                key: ValueKey(
                  'calendar-selected-status-${date.toIso8601String()}',
                ),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.foreground,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.onPrimary, width: 0.8),
                ),
              ),
            ],
            if (isBlocked)
              Container(
                width: 14,
                height: 1.5,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors(this.background, this.border, this.foreground);

  final Color background;
  final Color border;
  final Color foreground;
}

const double _statusFillOpacity = 0.10;
const double _darkStatusBorderOpacity = 0.34;
const double _lightStatusBorderOpacity = 0.24;

_StatusColors _entryColors(
  BuildContext context,
  CalendarEntryVisualStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return switch (status) {
      CalendarEntryVisualStatus.delivered => _StatusColors(
        AppColors.success.withValues(alpha: _statusFillOpacity),
        AppColors.success.withValues(alpha: _darkStatusBorderOpacity),
        const Color(0xFF75E7A3),
      ),
      CalendarEntryVisualStatus.notDelivered => _StatusColors(
        AppColors.danger.withValues(alpha: _statusFillOpacity),
        AppColors.danger.withValues(alpha: _darkStatusBorderOpacity),
        const Color(0xFFFF8EA1),
      ),
      CalendarEntryVisualStatus.quantityChanged => _StatusColors(
        AppColors.warning.withValues(alpha: _statusFillOpacity),
        AppColors.warning.withValues(alpha: _darkStatusBorderOpacity),
        const Color(0xFFFFB181),
      ),
      CalendarEntryVisualStatus.noEntry => _StatusColors(
        scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        scheme.outlineVariant.withValues(alpha: 0.70),
        scheme.onSurfaceVariant,
      ),
    };
  }
  return switch (status) {
    CalendarEntryVisualStatus.delivered => _StatusColors(
      AppColors.success.withValues(alpha: _statusFillOpacity),
      AppColors.success.withValues(alpha: _lightStatusBorderOpacity),
      AppColors.success,
    ),
    CalendarEntryVisualStatus.notDelivered => _StatusColors(
      AppColors.danger.withValues(alpha: _statusFillOpacity),
      AppColors.danger.withValues(alpha: _lightStatusBorderOpacity),
      AppColors.danger,
    ),
    CalendarEntryVisualStatus.quantityChanged => _StatusColors(
      AppColors.warning.withValues(alpha: _statusFillOpacity),
      AppColors.warning.withValues(alpha: _lightStatusBorderOpacity),
      AppColors.warning,
    ),
    CalendarEntryVisualStatus.noEntry => const _StatusColors(
      Color(0xFFF1F3F8),
      AppColors.line,
      AppColors.muted,
    ),
  };
}
