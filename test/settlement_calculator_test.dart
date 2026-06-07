import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/monthly_settlement.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_transaction.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_settlement_preview.dart';
import 'package:payqure_home/features/ledger/domain/services/payment_allocation_calculator.dart';
import 'package:payqure_home/features/ledger/domain/services/settlement_calculator.dart';

void main() {
  const calculator = SettlementCalculator();
  final now = DateTime(2026, 5, 20);

  PaymentTransaction payment(int cents, {bool pendingSync = false}) {
    return PaymentTransaction(
      id: 'payment-$cents',
      userId: 'user',
      serviceId: 'service',
      monthKey: '2026-05',
      amountCents: cents,
      paymentDate: now,
      mode: PaymentMode.cash,
      updatedAt: now,
      pendingSync: pendingSync,
    );
  }

  MonthlySettlement settlement({
    required int gross,
    int advance = 0,
    List<PaymentTransaction> payments = const [],
    MonthlySettlement? previous,
  }) {
    return calculator.calculate(
      userId: 'user',
      serviceId: 'service',
      monthKey: '2026-05',
      grossAmountCents: gross,
      manualAdvanceCents: advance,
      payments: payments,
      previousSettlement: previous,
      now: now,
    );
  }

  test('exact payment marks bill paid', () {
    final result = settlement(gross: 100000, payments: [payment(100000)]);

    expect(result.status, SettlementStatus.paid);
    expect(result.remainingAmountCents, 0);
    expect(result.carryForwardToNextMonthCents, 0);
    expect(result.advanceToNextMonthCents, 0);
  });

  test('zero remaining without a payment is not marked paid', () {
    final result = settlement(gross: 0);

    expect(result.paidAmountCents, 0);
    expect(result.status, SettlementStatus.pending);
  });

  test('partial payment carries remaining due forward', () {
    final result = settlement(gross: 100000, payments: [payment(70000)]);

    expect(result.status, SettlementStatus.partiallyPaid);
    expect(result.remainingAmountCents, 30000);
    expect(result.carryForwardToNextMonthCents, 30000);
  });

  test('extra payment becomes advance for next month', () {
    final result = settlement(gross: 100000, payments: [payment(130000)]);

    expect(result.status, SettlementStatus.overpaid);
    expect(result.remainingAmountCents, 0);
    expect(result.advanceToNextMonthCents, 30000);
  });

  test('previous carry forward is included in payable amount', () {
    final previous = MonthlySettlement(
      id: 'previous',
      userId: 'user',
      serviceId: 'service',
      monthKey: '2026-04',
      grossAmountCents: 100000,
      advanceUsedCents: 0,
      previousCarryForwardCents: 0,
      previousAdvanceCents: 0,
      payableAmountCents: 100000,
      paidAmountCents: 70000,
      remainingAmountCents: 30000,
      carryForwardToNextMonthCents: 30000,
      advanceToNextMonthCents: 0,
      status: SettlementStatus.partiallyPaid,
      generatedAt: now,
      updatedAt: now,
    );

    final result = settlement(
      gross: 100000,
      payments: [payment(130000)],
      previous: previous,
    );

    expect(result.status, SettlementStatus.paid);
    expect(result.payableAmountCents, 130000);
    expect(result.remainingAmountCents, 0);
  });

  test('previous advance reduces current payable amount', () {
    final previous = MonthlySettlement(
      id: 'previous',
      userId: 'user',
      serviceId: 'service',
      monthKey: '2026-04',
      grossAmountCents: 100000,
      advanceUsedCents: 0,
      previousCarryForwardCents: 0,
      previousAdvanceCents: 0,
      payableAmountCents: 100000,
      paidAmountCents: 130000,
      remainingAmountCents: 0,
      carryForwardToNextMonthCents: 0,
      advanceToNextMonthCents: 30000,
      status: SettlementStatus.overpaid,
      generatedAt: now,
      updatedAt: now,
    );

    final result = settlement(
      gross: 100000,
      payments: [payment(70000)],
      previous: previous,
    );

    expect(result.status, SettlementStatus.paid);
    expect(result.advanceUsedCents, 30000);
    expect(result.remainingAmountCents, 0);
  });

  test('offline payment remains visible as pending sync input', () {
    final offlinePayment = payment(100000, pendingSync: true);
    final result = settlement(gross: 100000, payments: [offlinePayment]);

    expect(offlinePayment.pendingSync, isTrue);
    expect(result.status, SettlementStatus.paid);
  });

  test('unallocated payment settles previous balance before current month', () {
    final previous = MonthlySettlement(
      id: 'previous',
      userId: 'user',
      serviceId: 'service',
      monthKey: '2026-05',
      grossAmountCents: 90000,
      advanceUsedCents: 0,
      previousCarryForwardCents: 0,
      previousAdvanceCents: 0,
      payableAmountCents: 90000,
      paidAmountCents: 70000,
      remainingAmountCents: 20000,
      carryForwardToNextMonthCents: 20000,
      advanceToNextMonthCents: 0,
      status: SettlementStatus.partiallyPaid,
      generatedAt: now,
      updatedAt: now,
    );

    final result = settlement(
      gross: 80000,
      payments: [payment(50000)],
      previous: previous,
    );

    expect(result.remainingAmountCents, 50000);
    expect(result.carryForwardToNextMonthCents, 50000);
    expect(result.status, SettlementStatus.partiallyPaid);
  });

  test('allocated payment records previous month before current month', () {
    final previous = MonthlySettlement(
      id: 'previous',
      userId: 'user',
      serviceId: 'service',
      monthKey: '2026-05',
      grossAmountCents: 90000,
      advanceUsedCents: 0,
      previousCarryForwardCents: 0,
      previousAdvanceCents: 0,
      payableAmountCents: 90000,
      paidAmountCents: 70000,
      remainingAmountCents: 20000,
      carryForwardToNextMonthCents: 20000,
      advanceToNextMonthCents: 0,
      status: SettlementStatus.partiallyPaid,
      generatedAt: now,
      updatedAt: now,
    );
    final allocatedPayment = payment(110000).copyWith(
      currentMonthAmountCents: 80000,
      previousBalanceAmountCents: 20000,
      advanceAmountCents: 10000,
    );

    final result = settlement(
      gross: 80000,
      payments: [allocatedPayment],
      previous: previous,
    );

    expect(result.remainingAmountCents, 0);
    expect(result.advanceToNextMonthCents, 10000);
    expect(result.status, SettlementStatus.overpaid);
  });

  test('payment preview allocates oldest pending months first', () {
    const allocator = PaymentAllocationCalculator();

    final preview = allocator.previewOldestFirst(
      paymentCents: 350000,
      dueMonths: const [
        PaymentMonthAllocation(
          monthKey: '2026-04',
          dueBeforePaymentCents: 150000,
          allocatedCents: 0,
        ),
        PaymentMonthAllocation(
          monthKey: '2026-05',
          dueBeforePaymentCents: 250000,
          allocatedCents: 0,
        ),
        PaymentMonthAllocation(
          monthKey: '2026-06',
          dueBeforePaymentCents: 220000,
          allocatedCents: 0,
        ),
      ],
    );

    expect(preview.totalDueCents, 620000);
    expect(preview.months[0].allocatedCents, 150000);
    expect(preview.months[0].remainingCents, 0);
    expect(preview.months[1].allocatedCents, 200000);
    expect(preview.months[1].remainingCents, 50000);
    expect(preview.months[2].allocatedCents, 0);
    expect(preview.advanceCents, 0);
  });
}
