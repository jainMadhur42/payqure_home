import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/advance_payment.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/monthly_settlement.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_transaction.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/services/cutoff_date_resolver.dart';
import 'package:payqure_home/features/ledger/domain/services/entry_amount_calculator.dart';
import 'package:payqure_home/features/ledger/domain/services/monthly_usage_calculator.dart';
import 'package:payqure_home/features/ledger/domain/services/till_date_settlement_calculator.dart';

void main() {
  const cutoffResolver = CutoffDateResolver();
  const usageCalculator = MonthlyUsageCalculator();
  const settlementCalculator = TillDateSettlementCalculator();
  const entryAmountCalculator = EntryAmountCalculator();

  group('CutoffDateResolver', () {
    test('current month resolves to today', () {
      final cutoff = cutoffResolver.resolve(
        selectedMonth: 5,
        selectedYear: 2026,
        today: DateTime(2026, 5, 8),
      );

      expect(cutoff, DateTime(2026, 5, 8));
    });

    test('past month resolves to last day of month', () {
      final cutoff = cutoffResolver.resolve(
        selectedMonth: 4,
        selectedYear: 2026,
        today: DateTime(2026, 5, 8),
      );

      expect(cutoff, DateTime(2026, 4, 30));
    });

    test('future month resolves before month start', () {
      final cutoff = cutoffResolver.resolve(
        selectedMonth: 6,
        selectedYear: 2026,
        today: DateTime(2026, 5, 8),
      );

      expect(cutoff, DateTime(2026, 5, 31));
    });
  });

  test('milkman till-date handles quantity change and missed day', () {
    final service = _service(
      entries: [
        for (var day = 1; day <= 5; day++)
          _entry(day: day, quantity: 1, amountCents: 6000),
        _entry(day: 6, quantity: 2, amountCents: 12000),
        _entry(
          day: 7,
          status: ServiceEntryStatus.notDelivered,
          quantity: 0,
          amountCents: 0,
        ),
      ],
    );

    final usage = usageCalculator.calculate(
      service: service,
      monthKey: '2026-05',
      cutoffDate: DateTime(2026, 5, 8),
    );

    expect(usage.usageAmountCents, 42000);
    expect(usage.deliveredDays, 6);
    expect(usage.missedDays, 1);
    expect(usage.totalQuantity, 7);
  });

  test('auto-mark disabled treats missing entries as zero', () {
    final usage = usageCalculator.calculate(
      service: _service(entries: const []),
      monthKey: '2026-05',
      cutoffDate: DateTime(2026, 5, 3),
      autoMarkDefault: false,
    );

    expect(usage.usageAmountCents, 0);
    expect(usage.deliveredDays, 0);
  });

  test('auto-mark enabled uses service defaults through cutoff', () {
    final usage = usageCalculator.calculate(
      service: _service(entries: const []),
      monthKey: '2026-05',
      cutoffDate: DateTime(2026, 5, 3),
      autoMarkDefault: true,
    );

    expect(usage.usageAmountCents, 18000);
    expect(usage.deliveredDays, 3);
  });

  test('entry-specific rate change is date-wise', () {
    final service = _service(
      entries: [
        _entry(day: 1, quantity: 1, rateCents: 6000, amountCents: 6000),
        _entry(
          day: 2,
          quantity: 1,
          rateCents: 6500,
          amountCents: 6500,
          status: ServiceEntryStatus.rateChanged,
        ),
      ],
    );

    final usage = usageCalculator.calculate(
      service: service,
      monthKey: '2026-05',
      cutoffDate: DateTime(2026, 5, 2),
    );

    expect(usage.usageAmountCents, 12500);
  });

  test('service start date mid-month excludes earlier days', () {
    final usage = usageCalculator.calculate(
      service: _service(
        description: 'Provider: Test • Start date: 03/05/2026',
        entries: const [],
      ),
      monthKey: '2026-05',
      cutoffDate: DateTime(2026, 5, 5),
      autoMarkDefault: true,
    );

    expect(usage.usageAmountCents, 18000);
    expect(usage.deliveredDays, 3);
  });

  test(
    'settlement adds previous pending and deducts advances and payments',
    () {
      final result = settlementCalculator.calculate(
        usageAmountCents: 42000,
        advances: [_advance(10000)],
        payments: [_payment(0)],
        previousSettlement: _previousSettlement(
          carryForwardCents: 30000,
          advanceCents: 0,
        ),
      );

      expect(result.netDueCents, 62000);
      expect(result.carryForwardCents, 62000);
      expect(result.advanceUsedCents, 10000);
    },
  );

  test('partial payment carries remaining forward', () {
    final result = settlementCalculator.calculate(
      usageAmountCents: 100000,
      advances: const [],
      payments: [_payment(30000)],
    );

    expect(result.status, SettlementStatus.partiallyPaid);
    expect(result.carryForwardCents, 70000);
  });

  test('extra payment becomes advance balance', () {
    final result = settlementCalculator.calculate(
      usageAmountCents: 100000,
      advances: const [],
      payments: [_payment(120000)],
    );

    expect(result.status, SettlementStatus.overpaid);
    expect(result.advanceBalanceCents, 20000);
  });

  test('previous advance reduces current month due', () {
    final result = settlementCalculator.calculate(
      usageAmountCents: 100000,
      advances: const [],
      payments: const [],
      previousSettlement: _previousSettlement(
        carryForwardCents: 0,
        advanceCents: 40000,
      ),
    );

    expect(result.netDueCents, 60000);
    expect(result.advanceUsedCents, 40000);
  });

  test('attendance present absent and half-day amounts', () {
    final service = _service(
      templateType: ServiceTemplateType.attendance,
      unit: 'Day',
      rateCents: 35000,
      entries: [
        _entry(
          day: 1,
          quantity: 1,
          unit: 'Day',
          rateCents: 35000,
          amountCents: 35000,
        ),
        _entry(
          day: 2,
          status: ServiceEntryStatus.notDelivered,
          quantity: 0,
          unit: 'Day',
          rateCents: 35000,
          amountCents: 0,
        ),
        _entry(
          day: 3,
          status: ServiceEntryStatus.halfDay,
          quantity: 0.5,
          unit: 'Day',
          rateCents: 35000,
          amountCents: 17500,
        ),
      ],
    );

    final usage = usageCalculator.calculate(
      service: service,
      monthKey: '2026-05',
      cutoffDate: DateTime(2026, 5, 3),
    );

    expect(usage.usageAmountCents, 52500);
    expect(usage.deliveredDays, 2);
    expect(usage.missedDays, 1);
  });

  test('amount field calculation is deterministic', () {
    final amount = entryAmountCalculator.calculate(
      service: _service(entries: const []),
      status: ServiceEntryStatus.delivered,
      quantity: 1.5,
      rateCents: 6000,
    );

    expect(amount.amountCents, 9000);
    expect(amount.detail, r'1.5 L x $60');
  });
}

HouseholdService _service({
  List<ServiceEntry> entries = const [],
  String description = 'Provider: Test',
  ServiceTemplateType templateType = ServiceTemplateType.quantity,
  String unit = 'L',
  int rateCents = 6000,
}) {
  return HouseholdService(
    id: 'service-1',
    userId: 'user-1',
    name: 'Service',
    description: description,
    icon: 'water',
    templateType: templateType,
    monthKey: '2026-05',
    unit: unit,
    defaultQuantity: 1,
    rateCents: rateCents,
    monthlyAmountCents: 0,
    entries: entries,
    updatedAt: DateTime(2026, 5),
  );
}

ServiceEntry _entry({
  required int day,
  ServiceEntryStatus status = ServiceEntryStatus.delivered,
  double quantity = 1,
  String unit = 'L',
  int rateCents = 6000,
  int amountCents = 6000,
}) {
  return ServiceEntry(
    id: 'entry-$day',
    serviceId: 'service-1',
    day: day,
    monthKey: '2026-05',
    status: status,
    quantity: quantity,
    unit: unit,
    rateCents: rateCents,
    amountCents: amountCents,
    updatedAt: DateTime(2026, 5, day),
  );
}

AdvancePayment _advance(int amountCents) {
  return AdvancePayment(
    id: 'advance-$amountCents',
    serviceId: 'service-1',
    monthKey: '2026-05',
    amountCents: amountCents,
    paidOn: DateTime(2026, 5, 1),
  );
}

PaymentTransaction _payment(int amountCents) {
  return PaymentTransaction(
    id: 'payment-$amountCents',
    userId: 'user-1',
    serviceId: 'service-1',
    monthKey: '2026-05',
    amountCents: amountCents,
    paymentDate: DateTime(2026, 5, 1),
    mode: PaymentMode.cash,
    updatedAt: DateTime(2026, 5, 1),
  );
}

MonthlySettlement _previousSettlement({
  required int carryForwardCents,
  required int advanceCents,
}) {
  return MonthlySettlement(
    id: 'previous',
    userId: 'user-1',
    serviceId: 'service-1',
    monthKey: '2026-04',
    grossAmountCents: 0,
    advanceUsedCents: 0,
    previousCarryForwardCents: 0,
    previousAdvanceCents: 0,
    payableAmountCents: carryForwardCents,
    paidAmountCents: 0,
    remainingAmountCents: carryForwardCents,
    carryForwardToNextMonthCents: carryForwardCents,
    advanceToNextMonthCents: advanceCents,
    status: carryForwardCents > 0
        ? SettlementStatus.pending
        : advanceCents > 0
        ? SettlementStatus.overpaid
        : SettlementStatus.paid,
    generatedAt: DateTime(2026, 4, 30),
    updatedAt: DateTime(2026, 4, 30),
  );
}
