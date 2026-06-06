import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/services/payment_allocation_calculator.dart';

void main() {
  const calculator = PaymentAllocationCalculator();

  test('water payment settles current, previous, then creates advance', () {
    final allocation = calculator.calculate(
      paymentCents: 110000,
      currentMonthDueCents: 80000,
      previousBalanceCents: 20000,
    );

    expect(allocation.currentMonthCents, 80000);
    expect(allocation.previousBalanceCents, 20000);
    expect(allocation.advanceCents, 10000);
  });

  test('milk payment leaves part of previous balance pending', () {
    final allocation = calculator.calculate(
      paymentCents: 150000,
      currentMonthDueCents: 130000,
      previousBalanceCents: 30000,
    );

    expect(allocation.currentMonthCents, 130000);
    expect(allocation.previousBalanceCents, 20000);
    expect(allocation.advanceCents, 0);
  });
}
