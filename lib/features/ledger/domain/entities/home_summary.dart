import 'household_service.dart';

class HomeMonthlySummary {
  const HomeMonthlySummary({
    required this.totalDueCents,
    required this.usageCents,
    required this.previousPendingCents,
    required this.paidCents,
    required this.advanceCents,
    required this.serviceCount,
  });

  final int totalDueCents;
  final int usageCents;
  final int previousPendingCents;
  final int paidCents;
  final int advanceCents;
  final int serviceCount;
}

class HomeServiceSummary {
  const HomeServiceSummary({
    required this.service,
    required this.metricLabel,
    required this.payableCents,
    required this.paidCents,
    required this.remainingCents,
    required this.advanceCents,
    required this.usageCents,
    required this.previousPendingCents,
    required this.advanceUsedCents,
    required this.deliveredDays,
    required this.missedDays,
    required this.totalQuantity,
    required this.statusLabel,
    required this.primaryLabel,
    required this.primaryAmountCents,
  });

  final HouseholdService service;
  final String metricLabel;
  final int payableCents;
  final int paidCents;
  final int remainingCents;
  final int advanceCents;
  final int usageCents;
  final int previousPendingCents;
  final int advanceUsedCents;
  final int deliveredDays;
  final int missedDays;
  final double totalQuantity;
  final String statusLabel;
  final String primaryLabel;
  final int primaryAmountCents;
}
