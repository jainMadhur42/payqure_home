import 'household_service.dart';

enum ServiceHistoryType { payment, advance }

class ServiceHistoryItem {
  const ServiceHistoryItem({
    required this.id,
    required this.service,
    required this.type,
    required this.amountCents,
    required this.date,
    required this.modeLabel,
    required this.note,
    required this.pendingSync,
  });

  final String id;
  final HouseholdService service;
  final ServiceHistoryType type;
  final int amountCents;
  final DateTime date;
  final String modeLabel;
  final String note;
  final bool pendingSync;
}
