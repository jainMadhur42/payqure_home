import '../entities/household_service.dart';
import '../entities/service_metadata.dart';

class ServiceReminderPlan {
  const ServiceReminderPlan({
    required this.notificationId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceTimeLabel,
    required this.hour,
    required this.minute,
  });

  final int notificationId;
  final String serviceId;
  final String serviceName;
  final String serviceTimeLabel;
  final int hour;
  final int minute;
}

class ServiceReminderPlanner {
  const ServiceReminderPlanner();

  List<ServiceReminderPlan> plansFor(
    List<HouseholdService> services, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    return services
        .map((service) => planFor(service, now: today))
        .whereType<ServiceReminderPlan>()
        .toList(growable: false);
  }

  ServiceReminderPlan? planFor(HouseholdService service, {DateTime? now}) {
    final metadata = ServiceMetadata.parse(service.description);
    if (metadata.remindBeforeMinutes <= 0) {
      return null;
    }
    final startDate = metadata.startDate;
    final today = now ?? DateTime.now();
    if (startDate != null &&
        DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).isAfter(DateTime(today.year, today.month, today.day))) {
      return null;
    }
    final serviceTime = _parseTime(metadata.serviceTime);
    if (serviceTime == null) {
      return null;
    }
    final serviceMinutes = serviceTime.$1 * 60 + serviceTime.$2;
    final reminderMinutes =
        (serviceMinutes - metadata.remindBeforeMinutes) % (24 * 60);
    return ServiceReminderPlan(
      notificationId: _notificationId(service.id),
      serviceId: service.id,
      serviceName: service.name,
      serviceTimeLabel: metadata.serviceTime,
      hour: reminderMinutes ~/ 60,
      minute: reminderMinutes % 60,
    );
  }

  (int, int)? _parseTime(String value) {
    final normalized = value.trim().toUpperCase();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
    ).firstMatch(normalized);
    if (match == null) {
      return null;
    }
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3);
    if (hour == null || minute == null || minute > 59) {
      return null;
    }
    if (period != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      if (period == 'AM') {
        hour %= 12;
      } else if (hour != 12) {
        hour += 12;
      }
    } else if (hour > 23) {
      return null;
    }
    return (hour, minute);
  }

  int _notificationId(String serviceId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in serviceId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
