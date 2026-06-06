import '../entities/advance_payment.dart';
import '../entities/monthly_settlement.dart';
import '../entities/payment_transaction.dart';

class TillDateSettlementResult {
  const TillDateSettlementResult({
    required this.usageAmountCents,
    required this.openingPendingCents,
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
  final int openingPendingCents;
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
    final grossDueBeforePayment =
        openingPending + usageAmountCents - availableAdvance;
    final netDue = grossDueBeforePayment - paid;
    final carryForward = netDue > 0 ? netDue : 0;
    final advanceBalance = netDue < 0 ? netDue.abs() : 0;
    final advanceUsed = availableAdvance.clamp(
      0,
      openingPending + usageAmountCents,
    );

    return TillDateSettlementResult(
      usageAmountCents: usageAmountCents,
      openingPendingCents: openingPending,
      openingAdvanceCents: openingAdvance,
      manualAdvanceCents: manualAdvance,
      availableAdvanceCents: availableAdvance,
      advanceUsedCents: advanceUsed,
      paidThisMonthCents: paid,
      netDueCents: netDue,
      carryForwardCents: carryForward,
      advanceBalanceCents: advanceBalance,
      status: _status(netDue: netDue, paid: paid),
    );
  }

  SettlementStatus _status({required int netDue, required int paid}) {
    if (netDue < 0) {
      return SettlementStatus.overpaid;
    }
    if (netDue == 0) {
      return SettlementStatus.paid;
    }
    if (paid > 0) {
      return SettlementStatus.partiallyPaid;
    }
    return SettlementStatus.pending;
  }
}
