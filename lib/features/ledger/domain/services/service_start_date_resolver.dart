import '../entities/household_service.dart';

class ServiceStartDateResolver {
  const ServiceStartDateResolver();

  DateTime? resolve(HouseholdService service) {
    final match = RegExp(
      r'Start date:\s*(\d{1,2})/(\d{1,2})/(\d{4})',
      caseSensitive: false,
    ).firstMatch(service.description);
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) {
      return null;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String? startMonthKey(HouseholdService service) {
    final date = resolve(service);
    if (date == null) {
      return null;
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  bool canUsePreviousSettlement({
    required HouseholdService service,
    required String selectedMonthKey,
  }) {
    final startMonth = startMonthKey(service);
    return startMonth == null || selectedMonthKey.compareTo(startMonth) > 0;
  }
}
