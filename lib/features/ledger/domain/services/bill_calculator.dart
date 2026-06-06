import '../entities/advance_payment.dart';
import '../entities/household_service.dart';
import '../entities/monthly_bill.dart';
import '../entities/service_entry.dart';
import '../entities/service_template.dart';
import 'monthly_usage_calculator.dart';

class BillCalculator {
  const BillCalculator()
    : _monthlyUsageCalculator = const MonthlyUsageCalculator();

  final MonthlyUsageCalculator _monthlyUsageCalculator;

  MonthlyBill calculate({
    required HouseholdService service,
    required List<AdvancePayment> advances,
  }) {
    final deliveredEntries = service.entries.where(
      (entry) => entry.status != ServiceEntryStatus.notDelivered,
    );
    final totalQuantity = deliveredEntries.fold<double>(
      0,
      (total, entry) => total + entry.quantity,
    );
    final gross = service.templateType == ServiceTemplateType.fixedMonthly
        ? _fixedMonthlyGross(service)
        : deliveredEntries.fold<int>(
            0,
            (total, entry) => total + entry.amountCents,
          );
    final advanceTotal = advances.fold<int>(
      0,
      (total, advance) => total + advance.amountCents,
    );

    return MonthlyBill(
      service: service,
      monthKey: service.monthKey,
      totalQuantity: totalQuantity,
      grossAmountCents: gross,
      advanceAmountCents: advanceTotal,
      payableAmountCents: gross - advanceTotal,
      advances: advances,
      lines: [
        BillLineItem(label: 'Gross Amount', amountCents: gross),
        if (advanceTotal > 0)
          BillLineItem(label: 'Less: Advance Paid', amountCents: -advanceTotal),
      ],
    );
  }

  int _fixedMonthlyGross(HouseholdService service) {
    final parts = service.monthKey.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    return _monthlyUsageCalculator
        .calculate(
          service: service,
          monthKey: service.monthKey,
          cutoffDate: DateTime(year, month + 1, 0),
        )
        .usageAmountCents;
  }
}
