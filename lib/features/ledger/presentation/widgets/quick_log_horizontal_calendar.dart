import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import 'ledger_screen_shared.dart';

class QuickLogHorizontalCalendar extends StatefulWidget {
  const QuickLogHorizontalCalendar({
    required this.monthKey,
    required this.selectedDate,
    required this.services,
    required this.onDateSelected,
    this.today,
    super.key,
  });

  final String monthKey;
  final DateTime selectedDate;
  final List<HouseholdService> services;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? today;

  @override
  State<QuickLogHorizontalCalendar> createState() =>
      _QuickLogHorizontalCalendarState();
}

class _QuickLogHorizontalCalendarState
    extends State<QuickLogHorizontalCalendar> {
  static const _minimumDayExtent = 44.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocusDay());
  }

  @override
  void didUpdateWidget(covariant QuickLogHorizontalCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monthKey != widget.monthKey ||
        oldWidget.selectedDate.day != widget.selectedDate.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocusDay());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final month = LedgerMonth.parse(widget.monthKey);
    final today = _dateOnly(widget.today ?? DateTime.now());
    final selectedDate = _dateOnly(widget.selectedDate);
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;
    final canJumpToToday =
        isCurrentMonth &&
        (selectedDate.year != today.year ||
            selectedDate.month != today.month ||
            selectedDate.day != today.day);

    return Semantics(
      label: 'Quick log calendar for ${monthLabelShort(widget.monthKey)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          monthLabelShort(widget.monthKey).toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 68,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.92,
                                    end: 1,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: canJumpToToday
                              ? TextButton(
                                  key: const ValueKey('quick-log-today'),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(68, 36),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _selectDate(today),
                                  child: const Text('Today'),
                                )
                              : const SizedBox(
                                  key: ValueKey('quick-log-today-hidden'),
                                  width: 68,
                                  height: 36,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 68,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dayExtent = _dayExtentForWidth(constraints.maxWidth);
                    return ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemExtent: dayExtent,
                      itemCount: month.daysInMonth,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final date = DateTime(month.year, month.month, day);
                        final dateOnly = _dateOnly(date);
                        final isSelected = _isSameDay(dateOnly, selectedDate);
                        final isToday = _isSameDay(dateOnly, today);
                        final isFuture = dateOnly.isAfter(today);
                        return _QuickLogDayItem(
                          key: ValueKey('quick-log-day-$day'),
                          date: date,
                          isSelected: isSelected,
                          isToday: isToday,
                          isComplete: _isComplete(day),
                          isEnabled: !isFuture,
                          onTap: () => _selectDate(date),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isComplete(int day) {
    if (widget.services.isEmpty) {
      return false;
    }
    return widget.services.every((service) {
      final entry = service.entries
          .where(
            (entry) => entry.day == day && entry.monthKey == widget.monthKey,
          )
          .firstOrNull;
      return entry != null && entry.status != ServiceEntryStatus.noEntry;
    });
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();
    widget.onDateSelected(_dateOnly(date));
  }

  void _scrollToFocusDay() {
    if (!_scrollController.hasClients) {
      return;
    }
    final month = LedgerMonth.parse(widget.monthKey);
    final today = _dateOnly(widget.today ?? DateTime.now());
    final selected = _dateOnly(widget.selectedDate);
    final focusDay =
        selected.year == month.year && selected.month == month.month
        ? selected.day
        : today.year == month.year && today.month == month.month
        ? today.day
        : 1;
    final viewport = _scrollController.position.viewportDimension;
    final dayExtent = _dayExtentForWidth(viewport);
    final target =
        ((focusDay - 1) * dayExtent) - (viewport / 2) + (dayExtent / 2);
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target.clamp(0, max).toDouble(),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  double _dayExtentForWidth(double width) {
    var visibleDayCount = (width / _minimumDayExtent).floor();
    if (visibleDayCount.isEven) {
      visibleDayCount -= 1;
    }
    visibleDayCount = visibleDayCount.clamp(3, 9);
    return width / visibleDayCount;
  }
}

class _QuickLogDayItem extends StatelessWidget {
  const _QuickLogDayItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isComplete,
    required this.isEnabled,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isComplete;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = isSelected
        ? colorScheme.onPrimary
        : isEnabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final weekdayColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      label:
          '${formatFullDate(date)}, ${isComplete ? 'all services logged' : 'entries pending'}',
      hint: isEnabled ? 'Select this date for quick log' : 'Future date',
      child: AnimatedScale(
        scale: isSelected ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(date.weekday),
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: weekdayColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: colorScheme.primary, width: 1.4)
                          : null,
                    ),
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    key: ValueKey('quick-log-day-complete-${date.day}'),
                    duration: const Duration(milliseconds: 180),
                    width: isComplete ? 6 : 0,
                    height: isComplete ? 6 : 0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _weekday(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      _ => 'Sun',
    };
  }
}
