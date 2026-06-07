import '../entities/household_service.dart';
import '../entities/service_metadata.dart';

class ServiceStartDateResolver {
  const ServiceStartDateResolver();

  DateTime? resolve(HouseholdService service) {
    return ServiceMetadata.parse(service.description).startDate;
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
