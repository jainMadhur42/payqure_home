import '../entities/home_summary.dart';
import '../entities/household_service.dart';
import '../entities/monthly_settlement.dart';
import '../entities/service_entry.dart';
import '../entities/service_template.dart';
import '../usecases/ledger_calculation_usecases.dart';

class HomeSummaryBuilder {
  const HomeSummaryBuilder();

  HomeServiceSummary buildServiceSummary({
    required HouseholdService service,
    required ServiceTillDateSummary tillDate,
  }) {
    final settlement = tillDate.settlement;
    final usageCents = settlement.usageAmountCents;
    final paidCents = settlement.paidThisMonthCents;
    final remainingCents = settlement.carryForwardCents;
    final advanceCents = settlement.advanceBalanceCents;

    return HomeServiceSummary(
      service: service,
      metricLabel: serviceMetric(service),
      payableCents: usageCents,
      paidCents: paidCents,
      remainingCents: remainingCents,
      advanceCents: advanceCents,
      usageCents: usageCents,
      previousPendingCents: settlement.previousBalanceRemainingCents,
      advanceUsedCents: settlement.advanceUsedCents,
      deliveredDays: tillDate.usage.deliveredDays,
      missedDays: tillDate.usage.missedDays,
      totalQuantity: tillDate.usage.totalQuantity,
      statusLabel: settlement.status.label,
      primaryLabel: _primaryLabel(
        settlement: settlement.status,
        remainingCents: remainingCents,
        advanceCents: advanceCents,
      ),
      primaryAmountCents: _primaryAmount(
        settlement: settlement.status,
        paidCents: paidCents,
        remainingCents: remainingCents,
        advanceCents: advanceCents,
      ),
    );
  }

  HomeMonthlySummary buildMonthlySummary(List<HomeServiceSummary> summaries) {
    return HomeMonthlySummary(
      totalDueCents: summaries.fold(
        0,
        (sum, summary) => sum + summary.remainingCents,
      ),
      usageCents: summaries.fold(0, (sum, summary) => sum + summary.usageCents),
      previousPendingCents: summaries.fold(
        0,
        (sum, summary) => sum + summary.previousPendingCents,
      ),
      paidCents: summaries.fold(0, (sum, summary) => sum + summary.paidCents),
      advanceCents: summaries.fold(
        0,
        (sum, summary) => sum + summary.advanceCents,
      ),
      serviceCount: summaries.length,
    );
  }

  String serviceMetric(HouseholdService service) {
    final loggedEntries = service.entries
        .where((entry) => entry.status != ServiceEntryStatus.noEntry)
        .toList();
    if (service.templateType == ServiceTemplateType.attendance) {
      final present = loggedEntries.where(_isDelivered).length;
      return '$present Present Days';
    }
    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      final delivered = loggedEntries.where(_isDelivered).length;
      return '$delivered Delivered Days';
    }
    final total = loggedEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.quantity,
    );
    final formatted = total.toStringAsFixed(
      total.truncateToDouble() == total ? 0 : 1,
    );
    final unit = service.unit.isEmpty ? 'Units' : service.unit;
    return '$formatted $unit this month';
  }

  bool _isDelivered(ServiceEntry entry) {
    return entry.status == ServiceEntryStatus.delivered ||
        entry.status == ServiceEntryStatus.rateChanged;
  }

  String _primaryLabel({
    required SettlementStatus settlement,
    required int remainingCents,
    required int advanceCents,
  }) {
    if (advanceCents > 0) {
      return 'Advance';
    }
    if (remainingCents > 0) {
      return 'Due till today';
    }
    if (settlement == SettlementStatus.paid) {
      return 'Paid';
    }
    return 'Pending';
  }

  int _primaryAmount({
    required SettlementStatus settlement,
    required int paidCents,
    required int remainingCents,
    required int advanceCents,
  }) {
    if (advanceCents > 0) {
      return advanceCents;
    }
    if (remainingCents > 0) {
      return remainingCents;
    }
    if (settlement == SettlementStatus.paid) {
      return paidCents;
    }
    return 0;
  }
}
