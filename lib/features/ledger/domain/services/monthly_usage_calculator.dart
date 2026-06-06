import '../entities/household_service.dart';
import '../entities/service_entry.dart';
import '../entities/service_template.dart';
import 'entry_amount_calculator.dart';
import 'rate_resolver.dart';
import 'service_start_date_resolver.dart';

class MonthlyUsageResult {
  const MonthlyUsageResult({
    required this.usageAmountCents,
    required this.deliveredDays,
    required this.missedDays,
    required this.totalQuantity,
    required this.cutoffDate,
  });

  final int usageAmountCents;
  final int deliveredDays;
  final int missedDays;
  final double totalQuantity;
  final DateTime cutoffDate;
}

class MonthlyUsageCalculator {
  const MonthlyUsageCalculator()
    : _entryAmountCalculator = const EntryAmountCalculator(),
      _rateResolver = const RateResolver(),
      _serviceStartDateResolver = const ServiceStartDateResolver();

  final EntryAmountCalculator _entryAmountCalculator;
  final RateResolver _rateResolver;
  final ServiceStartDateResolver _serviceStartDateResolver;

  MonthlyUsageResult calculate({
    required HouseholdService service,
    required String monthKey,
    required DateTime cutoffDate,
    bool autoMarkDefault = false,
  }) {
    final monthDate = _monthDate(monthKey);
    final monthStart = DateTime(monthDate.year, monthDate.month);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
    if (cutoffDate.isBefore(monthStart)) {
      return MonthlyUsageResult(
        usageAmountCents: 0,
        deliveredDays: 0,
        missedDays: 0,
        totalQuantity: 0,
        cutoffDate: cutoffDate,
      );
    }

    final serviceStart =
        _serviceStartDateResolver.resolve(service) ?? monthStart;
    final firstDay = serviceStart.isAfter(monthStart)
        ? serviceStart.day
        : monthStart.day;
    final lastDay = cutoffDate.isAfter(monthEnd)
        ? monthEnd.day
        : cutoffDate.day;
    if (firstDay > lastDay) {
      return MonthlyUsageResult(
        usageAmountCents: 0,
        deliveredDays: 0,
        missedDays: 0,
        totalQuantity: 0,
        cutoffDate: cutoffDate,
      );
    }

    final entriesByDay = {
      for (final entry in service.entries)
        if (entry.monthKey == monthKey) entry.day: entry,
    };

    var amount = 0;
    var deliveredDays = 0;
    var missedDays = 0;
    var totalQuantity = 0.0;
    for (var day = firstDay; day <= lastDay; day++) {
      final date = DateTime(monthDate.year, monthDate.month, day);
      final entry = entriesByDay[day];
      final effectiveEntry = entry ?? _defaultEntry(service, monthKey, day);
      if (entry == null && !autoMarkDefault) {
        continue;
      }
      if (effectiveEntry.status == ServiceEntryStatus.noEntry) {
        continue;
      }
      if (effectiveEntry.status == ServiceEntryStatus.notDelivered) {
        missedDays++;
        continue;
      }

      deliveredDays++;
      totalQuantity += effectiveEntry.quantity;
      amount += _entryAmountCalculator
          .calculate(
            service: service,
            status: effectiveEntry.status,
            quantity: effectiveEntry.quantity,
            rateCents: _rateResolver.resolve(
              service: service,
              entry: entry,
              date: date,
            ),
          )
          .amountCents;
    }

    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      amount = _fixedMonthlyAmount(
        monthlyAmountCents: service.monthlyAmountCents,
        deliveredDays: deliveredDays,
        daysInMonth: monthEnd.day,
      );
    }

    return MonthlyUsageResult(
      usageAmountCents: amount,
      deliveredDays: deliveredDays,
      missedDays: missedDays,
      totalQuantity: totalQuantity,
      cutoffDate: cutoffDate,
    );
  }

  int _fixedMonthlyAmount({
    required int monthlyAmountCents,
    required int deliveredDays,
    required int daysInMonth,
  }) {
    if (monthlyAmountCents <= 0 || deliveredDays <= 0 || daysInMonth <= 0) {
      return 0;
    }
    return (monthlyAmountCents * deliveredDays / daysInMonth).round();
  }

  ServiceEntry _defaultEntry(
    HouseholdService service,
    String monthKey,
    int day,
  ) {
    return ServiceEntry(
      id: 'default-${service.id}-$monthKey-$day',
      serviceId: service.id,
      day: day,
      monthKey: monthKey,
      status: ServiceEntryStatus.delivered,
      quantity: service.templateType == ServiceTemplateType.attendance
          ? 1
          : service.defaultQuantity,
      unit: service.unit,
      rateCents: service.rateCents,
      amountCents: 0,
      updatedAt: DateTime(1970),
    );
  }

  DateTime _monthDate(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    return DateTime(year, month);
  }
}
