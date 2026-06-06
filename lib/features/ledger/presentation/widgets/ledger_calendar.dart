import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/service_entry.dart';

class LedgerCalendar extends StatelessWidget {
  const LedgerCalendar({
    required this.entries,
    required this.monthKey,
    required this.onDaySelected,
    this.serviceStartDate,
    this.onBlockedDaySelected,
    this.selectedDay = 29,
    super.key,
  });

  final List<ServiceEntry> entries;
  final String monthKey;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final DateTime? serviceStartDate;
  final ValueChanged<DateTime>? onBlockedDaySelected;

  @override
  Widget build(BuildContext context) {
    final monthDate = _monthDate(monthKey);
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
          final entry = entryByDay[day];
          final status = isFuture
              ? CalendarDayStatus.noEntry
              : _calendarStatus(entry);
          return SizedBox.square(
            dimension: cellSize.clamp(44.0, 58.0),
            child: CalendarDayCell(
              date: date,
              status: status,
              isSelected: selected && !isBlocked,
              isToday: date == todayDate,
              isBlocked: isBlocked,
              onTap: () {
                if (isBlocked) {
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

  DateTime _monthDate(String key) {
    final parts = key.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    return DateTime(year, month);
  }

  CalendarDayStatus _calendarStatus(ServiceEntry? entry) {
    return switch (entry?.status ?? ServiceEntryStatus.noEntry) {
      ServiceEntryStatus.delivered => CalendarDayStatus.delivered,
      ServiceEntryStatus.notDelivered => CalendarDayStatus.notDelivered,
      ServiceEntryStatus.rateChanged => CalendarDayStatus.quantityChanged,
      ServiceEntryStatus.halfDay => CalendarDayStatus.quantityChanged,
      ServiceEntryStatus.noEntry => CalendarDayStatus.noEntry,
    };
  }
}

enum CalendarDayStatus { delivered, notDelivered, quantityChanged, noEntry }

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
  final CalendarDayStatus status;
  final bool isSelected;
  final bool isToday;
  final bool isBlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _entryColors(status);
    final textColor = isSelected
        ? Colors.white
        : isBlocked
        ? AppColors.muted.withValues(alpha: 0.55)
        : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isBlocked
              ? AppColors.background
              : colors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isBlocked
                ? AppColors.line.withValues(alpha: 0.45)
                : isToday
                ? AppColors.primary
                : isSelected
                ? AppColors.primary
                : colors.border,
          ),
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
            if (isBlocked)
              Container(
                width: 14,
                height: 1.5,
                color: AppColors.muted.withValues(alpha: 0.45),
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

_StatusColors _entryColors(CalendarDayStatus status) {
  return switch (status) {
    CalendarDayStatus.delivered => const _StatusColors(
      AppColors.successSoft,
      Color(0xFFBFE9CF),
      AppColors.success,
    ),
    CalendarDayStatus.notDelivered => const _StatusColors(
      AppColors.dangerSoft,
      Color(0xFFFFCAD2),
      AppColors.danger,
    ),
    CalendarDayStatus.quantityChanged => const _StatusColors(
      AppColors.warningSoft,
      Color(0xFFFFD7BD),
      AppColors.warning,
    ),
    CalendarDayStatus.noEntry => const _StatusColors(
      Color(0xFFF1F3F8),
      AppColors.line,
      AppColors.muted,
    ),
  };
}
