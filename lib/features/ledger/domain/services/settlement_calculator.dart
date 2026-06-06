import '../entities/monthly_settlement.dart';
import '../entities/payment_transaction.dart';

class SettlementCalculator {
  const SettlementCalculator();

  MonthlySettlement calculate({
    required String userId,
    required String serviceId,
    required String monthKey,
    required int grossAmountCents,
    required int manualAdvanceCents,
    required List<PaymentTransaction> payments,
    MonthlySettlement? previousSettlement,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final previousCarryForward =
        previousSettlement?.carryForwardToNextMonthCents ?? 0;
    final previousAdvance = previousSettlement?.advanceToNextMonthCents ?? 0;
    final totalDueBeforeAdvance = previousCarryForward + grossAmountCents;
    final availableAdvance = previousAdvance + manualAdvanceCents;
    final advanceUsed = availableAdvance > totalDueBeforeAdvance
        ? totalDueBeforeAdvance
        : availableAdvance;
    final payableBeforePayments = totalDueBeforeAdvance - advanceUsed;
    final paid = payments.fold<int>(0, (sum, payment) {
      if (payment.isDeleted) {
        return sum;
      }
      return sum + payment.amountCents;
    });
    final remainingAfterPayment = payableBeforePayments - paid;
    final carryForward = remainingAfterPayment > 0 ? remainingAfterPayment : 0;
    final advanceToNext = remainingAfterPayment < 0
        ? remainingAfterPayment.abs()
        : availableAdvance - advanceUsed;
    final status = _status(
      payableBeforePayments: payableBeforePayments,
      paidAmount: paid,
      remainingAmount: remainingAfterPayment,
    );

    return MonthlySettlement(
      id: '${userId}_${serviceId}_$monthKey',
      userId: userId,
      serviceId: serviceId,
      monthKey: monthKey,
      grossAmountCents: grossAmountCents,
      advanceUsedCents: advanceUsed,
      previousCarryForwardCents: previousCarryForward,
      previousAdvanceCents: previousAdvance,
      payableAmountCents: payableBeforePayments,
      paidAmountCents: paid,
      remainingAmountCents: carryForward,
      carryForwardToNextMonthCents: carryForward,
      advanceToNextMonthCents: advanceToNext,
      status: status,
      generatedAt: generatedAt,
      updatedAt: generatedAt,
      pendingSync: true,
    );
  }

  SettlementStatus _status({
    required int payableBeforePayments,
    required int paidAmount,
    required int remainingAmount,
  }) {
    if (remainingAmount < 0) {
      return SettlementStatus.overpaid;
    }
    if (remainingAmount == 0) {
      return SettlementStatus.paid;
    }
    if (paidAmount == 0) {
      return SettlementStatus.pending;
    }
    return SettlementStatus.partiallyPaid;
  }
}
