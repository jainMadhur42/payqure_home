import '../entities/household_service.dart';
import '../entities/service_entry.dart';
import '../entities/service_template.dart';
import 'entry_amount_calculator.dart';

class ResolvedEntryValue {
  const ResolvedEntryValue({
    required this.rateCents,
    required this.amountCents,
  });

  final int rateCents;
  final int amountCents;
}

class EntryValueResolver {
  const EntryValueResolver()
    : _entryAmountCalculator = const EntryAmountCalculator();

  final EntryAmountCalculator _entryAmountCalculator;

  ResolvedEntryValue resolve({
    required HouseholdService service,
    required ServiceEntry entry,
  }) {
    final rate =
        service.templateType == ServiceTemplateType.fixedMonthly ||
            (service.templateType == ServiceTemplateType.attendance &&
                service.monthlyAmountCents > 0)
        ? fixedDailyRateCents(service: service, monthKey: entry.monthKey)
        : entry.rateCents > 0
        ? entry.rateCents
        : service.rateCents;
    final amount = _entryAmountCalculator
        .calculate(
          service: service,
          status: entry.status,
          quantity: entry.quantity,
          rateCents: rate,
        )
        .amountCents;
    return ResolvedEntryValue(rateCents: rate, amountCents: amount);
  }

  int fixedDailyRateCents({
    required HouseholdService service,
    required String monthKey,
  }) {
    if (service.monthlyAmountCents <= 0) {
      return 0;
    }
    final parts = monthKey.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return (service.monthlyAmountCents / daysInMonth).round();
  }
}
