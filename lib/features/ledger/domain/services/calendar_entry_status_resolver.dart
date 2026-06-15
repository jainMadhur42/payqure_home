import '../entities/service_entry.dart';

enum CalendarEntryVisualStatus {
  delivered,
  notDelivered,
  quantityChanged,
  noEntry,
}

abstract final class CalendarEntryStatusResolver {
  static const _quantityTolerance = 0.000001;

  static CalendarEntryVisualStatus resolve({
    required ServiceEntry? entry,
    double? configuredQuantity,
  }) {
    if (entry == null || entry.status == ServiceEntryStatus.noEntry) {
      return CalendarEntryVisualStatus.noEntry;
    }
    if (entry.status == ServiceEntryStatus.delivered &&
        configuredQuantity != null &&
        (entry.quantity - configuredQuantity).abs() > _quantityTolerance) {
      return CalendarEntryVisualStatus.quantityChanged;
    }
    return switch (entry.status) {
      ServiceEntryStatus.delivered => CalendarEntryVisualStatus.delivered,
      ServiceEntryStatus.notDelivered => CalendarEntryVisualStatus.notDelivered,
      ServiceEntryStatus.rateChanged ||
      ServiceEntryStatus.halfDay => CalendarEntryVisualStatus.quantityChanged,
      ServiceEntryStatus.noEntry => CalendarEntryVisualStatus.noEntry,
    };
  }
}
