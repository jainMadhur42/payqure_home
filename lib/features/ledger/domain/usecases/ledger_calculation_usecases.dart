import '../entities/advance_payment.dart';
import '../entities/household_service.dart';
import '../entities/monthly_settlement.dart';
import '../entities/payment_transaction.dart';
import '../entities/service_entry.dart';
import '../services/cutoff_date_resolver.dart';
import '../services/entry_amount_calculator.dart';
import '../services/monthly_usage_calculator.dart';
import '../services/service_start_date_resolver.dart';
import '../services/till_date_settlement_calculator.dart';

class ServiceTillDateSummary {
  const ServiceTillDateSummary({required this.usage, required this.settlement});

  final MonthlyUsageResult usage;
  final TillDateSettlementResult settlement;
}

class CalculateEntryAmountUseCase {
  const CalculateEntryAmountUseCase()
    : _calculator = const EntryAmountCalculator();

  final EntryAmountCalculator _calculator;

  EntryAmountBreakdown call({
    required HouseholdService service,
    required ServiceEntryStatus status,
    required double quantity,
    required int rateCents,
  }) {
    return _calculator.calculate(
      service: service,
      status: status,
      quantity: quantity,
      rateCents: rateCents,
    );
  }
}

class GetServiceTillDateSummaryUseCase {
  const GetServiceTillDateSummaryUseCase()
    : _cutoffDateResolver = const CutoffDateResolver(),
      _monthlyUsageCalculator = const MonthlyUsageCalculator(),
      _serviceStartDateResolver = const ServiceStartDateResolver(),
      _settlementCalculator = const TillDateSettlementCalculator();

  final CutoffDateResolver _cutoffDateResolver;
  final MonthlyUsageCalculator _monthlyUsageCalculator;
  final ServiceStartDateResolver _serviceStartDateResolver;
  final TillDateSettlementCalculator _settlementCalculator;

  ServiceTillDateSummary call({
    required HouseholdService service,
    required String monthKey,
    required List<AdvancePayment> advances,
    required List<PaymentTransaction> payments,
    MonthlySettlement? previousSettlement,
    DateTime? today,
    bool autoMarkDefault = false,
  }) {
    final monthDate = _monthDate(monthKey);
    final cutoff = _cutoffDateResolver.resolve(
      selectedMonth: monthDate.month,
      selectedYear: monthDate.year,
      today: today ?? DateTime.now(),
    );
    final usage = _monthlyUsageCalculator.calculate(
      service: service,
      monthKey: monthKey,
      cutoffDate: cutoff,
      autoMarkDefault: autoMarkDefault,
    );
    final settlement = _settlementCalculator.calculate(
      usageAmountCents: usage.usageAmountCents,
      advances: advances,
      payments: payments,
      previousSettlement:
          _serviceStartDateResolver.canUsePreviousSettlement(
            service: service,
            selectedMonthKey: monthKey,
          )
          ? previousSettlement
          : null,
    );
    return ServiceTillDateSummary(usage: usage, settlement: settlement);
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
