import '../entities/household_service.dart';
import '../entities/service_entry.dart';

class RateResolver {
  const RateResolver();

  int resolve({
    required HouseholdService service,
    ServiceEntry? entry,
    required DateTime date,
  }) {
    return entry?.rateCents ?? service.rateCents;
  }
}
