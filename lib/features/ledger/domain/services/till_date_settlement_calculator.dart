import '../entities/advance_payment.dart';
import '../entities/monthly_settlement.dart';
import '../entities/payment_transaction.dart';

class TillDateSettlementResult {
  const TillDateSettlementResult({
    required this.usageAmountCents,
    required this.currentMonthRemainingCents,
    required this.openingPendingCents,
    required this.previousBalanceRemainingCents,
    required this.openingAdvanceCents,
    required this.manualAdvanceCents,
    required this.availableAdvanceCents,
    required this.advanceUsedCents,
    required this.paidThisMonthCents,
    required this.netDueCents,
    required this.carryForwardCents,
    required this.advanceBalanceCents,
    required this.status,
  });

  final int usageAmountCents;
  final int currentMonthRemainingCents;
  final int openingPendingCents;
  final int previousBalanceRemainingCents;
  final int openingAdvanceCents;
  final int manualAdvanceCents;
  final int availableAdvanceCents;
  final int advanceUsedCents;
  final int paidThisMonthCents;
  final int netDueCents;
  final int carryForwardCents;
  final int advanceBalanceCents;
  final SettlementStatus status;
}

class TillDateSettlementCalculator {
  const TillDateSettlementCalculator();

  TillDateSettlementResult calculate({
    required int usageAmountCents,
    required List<AdvancePayment> advances,
    required List<PaymentTransaction> payments,
    MonthlySettlement? previousSettlement,
  }) {
    final openingPending =
        previousSettlement?.carryForwardToNextMonthCents ?? 0;
    final openingAdvance = previousSettlement?.advanceToNextMonthCents ?? 0;
    final manualAdvance = advances.fold<int>(
      0,
      (sum, advance) => sum + advance.amountCents,
    );
    final paid = payments.fold<int>(
      0,
      (sum, payment) => payment.isDeleted ? sum : sum + payment.amountCents,
    );
    final availableAdvance = openingAdvance + manualAdvance;
    final currentAdvanceUsed = availableAdvance.clamp(0, usageAmountCents);
    final currentDue = usageAmountCents - currentAdvanceUsed;
    final advanceAfterCurrent = availableAdvance - currentAdvanceUsed;
    final previousAdvanceUsed = advanceAfterCurrent.clamp(0, openingPending);
    final previousDue = openingPending - previousAdvanceUsed;
    final allocatedCurrent = _allocated(
      payments,
      (payment) => payment.currentMonthAmountCents,
    );
    final allocatedPrevious = _allocated(
      payments,
      (payment) => payment.previousBalanceAmountCents,
    );
    final allocatedPaymentAdvance = _allocated(
      payments,
      (payment) => payment.advanceAmountCents,
    );
    final hasAllocations =
        allocatedCurrent + allocatedPrevious + allocatedPaymentAdvance > 0;
    final previousPaid = hasAllocations
        ? allocatedPrevious
        : paid.clamp(0, previousDue);
    final currentPaid = hasAllocations
        ? allocatedCurrent
        : (paid - previousPaid).clamp(0, currentDue);
    final paymentAdvance = hasAllocations
        ? allocatedPaymentAdvance
        : (paid - currentPaid - previousPaid).clamp(0, paid);
    final currentMonthRemaining = (currentDue - currentPaid).clamp(
      0,
      currentDue,
    );
    final previousBalanceRemaining = (previousDue - previousPaid).clamp(
      0,
      previousDue,
    );
    final netDue = currentMonthRemaining + previousBalanceRemaining;
    final carryForward = netDue > 0 ? netDue : 0;
    final advanceBalance =
        availableAdvance -
        currentAdvanceUsed -
        previousAdvanceUsed +
        paymentAdvance;
    final advanceUsed = currentAdvanceUsed + previousAdvanceUsed;

    return TillDateSettlementResult(
      usageAmountCents: usageAmountCents,
      currentMonthRemainingCents: currentMonthRemaining,
      openingPendingCents: openingPending,
      previousBalanceRemainingCents: previousBalanceRemaining,
      openingAdvanceCents: openingAdvance,
      manualAdvanceCents: manualAdvance,
      availableAdvanceCents: availableAdvance,
      advanceUsedCents: advanceUsed,
      paidThisMonthCents: paid,
      netDueCents: netDue,
      carryForwardCents: carryForward,
      advanceBalanceCents: advanceBalance,
      status: _status(
        netDue: netDue,
        paid: paid,
        advanceBalance: advanceBalance,
      ),
    );
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

  SettlementStatus _status({
    required int netDue,
    required int paid,
    required int advanceBalance,
  }) {
    if (advanceBalance > 0) {
      return SettlementStatus.overpaid;
    }
    if (netDue == 0 && paid > 0) {
      return SettlementStatus.paid;
    }
    if (paid > 0) {
      return SettlementStatus.partiallyPaid;
    }
    return SettlementStatus.pending;
  }
}
