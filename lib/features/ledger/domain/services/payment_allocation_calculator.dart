import '../entities/payment_settlement_preview.dart';

class PaymentAllocation {
  const PaymentAllocation({
    required this.currentMonthCents,
    required this.previousBalanceCents,
    required this.advanceCents,
  });

  final int currentMonthCents;
  final int previousBalanceCents;
  final int advanceCents;
}

class PaymentAllocationCalculator {
  const PaymentAllocationCalculator();

  PaymentAllocation calculate({
    required int paymentCents,
    required int currentMonthDueCents,
    required int previousBalanceCents,
  }) {
    var remaining = paymentCents.clamp(0, paymentCents);
    final previous = remaining.clamp(0, previousBalanceCents);
    remaining -= previous;
    final current = remaining.clamp(0, currentMonthDueCents);
    remaining -= current;

    return PaymentAllocation(
      currentMonthCents: current,
      previousBalanceCents: previous,
      advanceCents: remaining,
    );
  }

  PaymentSettlementPreview previewOldestFirst({
    required int paymentCents,
    required List<PaymentMonthAllocation> dueMonths,
  }) {
    var remainingPayment = paymentCents.clamp(0, paymentCents);
    final allocations = <PaymentMonthAllocation>[];
    for (final month in dueMonths) {
      final allocated = remainingPayment.clamp(0, month.dueBeforePaymentCents);
      remainingPayment -= allocated;
      allocations.add(
        PaymentMonthAllocation(
          monthKey: month.monthKey,
          dueBeforePaymentCents: month.dueBeforePaymentCents,
          allocatedCents: allocated,
        ),
      );
    }
    return PaymentSettlementPreview(
      totalDueCents: dueMonths.fold<int>(
        0,
        (sum, month) => sum + month.dueBeforePaymentCents,
      ),
      paymentCents: paymentCents,
      months: allocations,
      advanceCents: remainingPayment,
    );
  }
}
