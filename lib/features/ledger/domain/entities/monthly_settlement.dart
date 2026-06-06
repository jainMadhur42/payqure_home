enum SettlementStatus { pending, paid, partiallyPaid, overpaid }

class MonthlySettlement {
  const MonthlySettlement({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.monthKey,
    required this.grossAmountCents,
    required this.advanceUsedCents,
    required this.previousCarryForwardCents,
    required this.previousAdvanceCents,
    required this.payableAmountCents,
    required this.paidAmountCents,
    required this.remainingAmountCents,
    required this.carryForwardToNextMonthCents,
    required this.advanceToNextMonthCents,
    required this.status,
    required this.generatedAt,
    required this.updatedAt,
    this.pendingSync = false,
  });

  final String id;
  final String userId;
  final String serviceId;
  final String monthKey;
  final int grossAmountCents;
  final int advanceUsedCents;
  final int previousCarryForwardCents;
  final int previousAdvanceCents;
  final int payableAmountCents;
  final int paidAmountCents;
  final int remainingAmountCents;
  final int carryForwardToNextMonthCents;
  final int advanceToNextMonthCents;
  final SettlementStatus status;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final bool pendingSync;
}

extension SettlementStatusLabel on SettlementStatus {
  String get label {
    return switch (this) {
      SettlementStatus.pending => 'Pending',
      SettlementStatus.paid => 'Paid',
      SettlementStatus.partiallyPaid => 'Partially Paid',
      SettlementStatus.overpaid => 'Overpaid',
    };
  }
}
