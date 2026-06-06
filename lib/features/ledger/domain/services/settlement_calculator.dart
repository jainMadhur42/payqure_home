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
    final availableAdvance = previousAdvance + manualAdvanceCents;
    final currentAdvanceUsed = availableAdvance.clamp(0, grossAmountCents);
    final currentDue = grossAmountCents - currentAdvanceUsed;
    final advanceAfterCurrent = availableAdvance - currentAdvanceUsed;
    final previousAdvanceUsed = advanceAfterCurrent.clamp(
      0,
      previousCarryForward,
    );
    final previousDue = previousCarryForward - previousAdvanceUsed;
    final advanceUsed = currentAdvanceUsed + previousAdvanceUsed;
    final payableBeforePayments = currentDue + previousDue;
    final paid = payments.fold<int>(0, (sum, payment) {
      if (payment.isDeleted) {
        return sum;
      }
      return sum + payment.amountCents;
    });
    final allocatedCurrent = _allocated(
      payments,
      (payment) => payment.currentMonthAmountCents,
    );
    final allocatedPrevious = _allocated(
      payments,
      (payment) => payment.previousBalanceAmountCents,
    );
    final allocatedAdvance = _allocated(
      payments,
      (payment) => payment.advanceAmountCents,
    );
    final hasAllocations =
        allocatedCurrent + allocatedPrevious + allocatedAdvance > 0;
    final currentPaid = hasAllocations
        ? allocatedCurrent
        : paid.clamp(0, currentDue);
    final previousPaid = hasAllocations
        ? allocatedPrevious
        : (paid - currentPaid).clamp(0, previousDue);
    final paymentAdvance = hasAllocations
        ? allocatedAdvance
        : (paid - currentPaid - previousPaid).clamp(0, paid);
    final carryForward =
        (currentDue - currentPaid) + (previousDue - previousPaid);
    final advanceToNext = availableAdvance - advanceUsed + paymentAdvance;
    final status = _status(
      payableBeforePayments: payableBeforePayments,
      paidAmount: paid,
      remainingAmount: carryForward,
      advanceAmount: advanceToNext,
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
    required int advanceAmount,
  }) {
    if (advanceAmount > 0) {
      return SettlementStatus.overpaid;
    }
    if (remainingAmount == 0 && paidAmount > 0) {
      return SettlementStatus.paid;
    }
    if (paidAmount == 0) {
      return SettlementStatus.pending;
    }
    return SettlementStatus.partiallyPaid;
  }

  int _allocated(
    List<PaymentTransaction> payments,
    int Function(PaymentTransaction payment) selector,
  ) {
    return payments.fold<int>(
      0,
      (sum, payment) => payment.isDeleted ? sum : sum + selector(payment),
    );
  }
}
