import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/home_summary.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/ledger_month.dart';
import 'package:payqure_home/features/ledger/domain/entities/monthly_settlement.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/services/home_summary_builder.dart';
import 'package:payqure_home/features/ledger/domain/services/monthly_usage_calculator.dart';
import 'package:payqure_home/features/ledger/domain/services/till_date_settlement_calculator.dart';
import 'package:payqure_home/features/ledger/domain/usecases/ledger_calculation_usecases.dart';

void main() {
  const builder = HomeSummaryBuilder();

  group('LedgerMonth', () {
    test('normalizes and shifts across year boundaries', () {
      expect(LedgerMonth(2026, 13).key, '2027-01');
      expect(LedgerMonth.parse('2026-01').shift(-1).key, '2025-12');
    });

    test('falls back safely for malformed values', () {
      final month = LedgerMonth.parse('invalid', fallback: DateTime(2026, 6));

      expect(month.key, '2026-06');
    });
  });

  test('builds a quantity service summary from domain output', () {
    final service = _service(
      entries: [_entry(day: 1, quantity: 1), _entry(day: 2, quantity: 1.5)],
    );
    final summary = builder.buildServiceSummary(
      service: service,
      tillDate: ServiceTillDateSummary(
        usage: MonthlyUsageResult(
          usageAmountCents: 15000,
          deliveredDays: 2,
          missedDays: 0,
          totalQuantity: 2.5,
          cutoffDate: DateTime(2026, 6, 2),
        ),
        settlement: const TillDateSettlementResult(
          usageAmountCents: 15000,
          currentMonthRemainingCents: 12000,
          openingPendingCents: 2000,
          previousBalanceRemainingCents: 2000,
          openingAdvanceCents: 0,
          manualAdvanceCents: 0,
          availableAdvanceCents: 0,
          advanceUsedCents: 0,
          paidThisMonthCents: 5000,
          netDueCents: 14000,
          carryForwardCents: 14000,
          advanceBalanceCents: 0,
          status: SettlementStatus.partiallyPaid,
        ),
      ),
    );

    expect(summary.metricLabel, '2.5 L this month');
    expect(summary.primaryLabel, 'Due till today');
    expect(summary.primaryAmountCents, 14000);
    expect(summary.statusLabel, 'Partially Paid');
  });

  test('aggregates monthly summary without presentation state', () {
    final service = _service();
    final first = _homeSummary(service, remaining: 1000, usage: 1200);
    final second = _homeSummary(service, remaining: 2000, usage: 2500);

    final summary = builder.buildMonthlySummary([first, second]);

    expect(summary.totalDueCents, 3000);
    expect(summary.usageCents, 3700);
    expect(summary.serviceCount, 2);
  });
}

HouseholdService _service({List<ServiceEntry> entries = const []}) {
  return HouseholdService(
    id: 'service',
    userId: 'user',
    name: 'Milkman',
    description: '',
    icon: 'milk',
    templateType: ServiceTemplateType.quantity,
    monthKey: '2026-06',
    unit: 'L',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: entries,
    updatedAt: DateTime(2026, 6, 1),
  );
}

ServiceEntry _entry({required int day, required double quantity}) {
  return ServiceEntry(
    id: 'entry-$day',
    serviceId: 'service',
    day: day,
    monthKey: '2026-06',
    status: ServiceEntryStatus.delivered,
    quantity: quantity,
    unit: 'L',
    rateCents: 6000,
    amountCents: (quantity * 6000).round(),
    updatedAt: DateTime(2026, 6, day),
  );
}

HomeServiceSummary _homeSummary(
  HouseholdService service, {
  required int remaining,
  required int usage,
}) {
  return HomeServiceSummary(
    service: service,
    metricLabel: '',
    payableCents: usage,
    paidCents: 0,
    remainingCents: remaining,
    advanceCents: 0,
    usageCents: usage,
    previousPendingCents: 0,
    advanceUsedCents: 0,
    deliveredDays: 0,
    missedDays: 0,
    totalQuantity: 0,
    statusLabel: 'Pending',
    primaryLabel: 'Due till today',
    primaryAmountCents: remaining,
  );
}
