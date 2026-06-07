class PaymentMonthAllocation {
  const PaymentMonthAllocation({
    required this.monthKey,
    required this.dueBeforePaymentCents,
    required this.allocatedCents,
  });

  final String monthKey;
  final int dueBeforePaymentCents;
  final int allocatedCents;

  int get remainingCents =>
      (dueBeforePaymentCents - allocatedCents).clamp(0, dueBeforePaymentCents);
}

class PaymentSettlementPreview {
  const PaymentSettlementPreview({
    required this.totalDueCents,
    required this.paymentCents,
    required this.months,
    required this.advanceCents,
  });

  final int totalDueCents;
  final int paymentCents;
  final List<PaymentMonthAllocation> months;
  final int advanceCents;

  int get remainingDueCents =>
      months.fold<int>(0, (sum, month) => sum + month.remainingCents);
}
