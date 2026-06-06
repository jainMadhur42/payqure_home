import '../entities/household_service.dart';
import '../entities/service_entry.dart';
import '../entities/service_template.dart';
import 'entry_amount_calculator.dart';
import 'rate_resolver.dart';

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
      _rateResolver = const RateResolver();

  final EntryAmountCalculator _entryAmountCalculator;
  final RateResolver _rateResolver;

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

    final serviceStart = _serviceStartDate(service) ?? monthStart;
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

    return MonthlyUsageResult(
      usageAmountCents: amount,
      deliveredDays: deliveredDays,
      missedDays: missedDays,
      totalQuantity: totalQuantity,
      cutoffDate: cutoffDate,
    );
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

  DateTime? _serviceStartDate(HouseholdService service) {
    for (final item in service.description.split(' • ')) {
      final separator = item.indexOf(':');
      if (separator == -1) {
        continue;
      }
      final label = item.substring(0, separator).trim().toLowerCase();
      if (label != 'start date') {
        continue;
      }
      final parts = item.substring(separator + 1).trim().split('/');
      if (parts.length != 3) {
        return null;
      }
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) {
        return null;
      }
      return DateTime(year, month, day);
    }
    return null;
  }
}
