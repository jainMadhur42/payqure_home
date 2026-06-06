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
    final current = remaining.clamp(0, currentMonthDueCents);
    remaining -= current;
    final previous = remaining.clamp(0, previousBalanceCents);
    remaining -= previous;

    return PaymentAllocation(
      currentMonthCents: current,
      previousBalanceCents: previous,
      advanceCents: remaining,
    );
  }
}
