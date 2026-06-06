import 'household_service.dart';
import 'user_profile.dart';

class LedgerOverview {
  const LedgerOverview({
    required this.profile,
    required this.monthKey,
    required this.monthLabel,
    required this.services,
    required this.totalPayableCents,
    required this.advancePaidCents,
  });

  final UserProfile profile;
  final String monthKey;
  final String monthLabel;
  final List<HouseholdService> services;
  final int totalPayableCents;
  final int advancePaidCents;

  int get totalPayable => (totalPayableCents / 100).round();

  int get advancePaid => (advancePaidCents / 100).round();
}
