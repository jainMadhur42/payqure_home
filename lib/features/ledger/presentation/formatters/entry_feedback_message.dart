import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

abstract final class EntryFeedbackMessage {
  static String statusUpdated({
    required int day,
    required ServiceEntryStatus status,
    required ServiceTemplateType templateType,
  }) {
    return '$day has been marked as ${_statusLabel(status, templateType)}.';
  }

  static String customized({
    required int day,
    required ServiceEntry entry,
    required ServiceTemplateType templateType,
  }) {
    if (templateType == ServiceTemplateType.quantity &&
        entry.status == ServiceEntryStatus.delivered) {
      final unit = entry.unit.trim();
      final quantity = _formatQuantity(entry.quantity);
      return '$day quantity has been updated to '
          '$quantity${unit.isEmpty ? '' : ' $unit'}.';
    }
    return statusUpdated(
      day: day,
      status: entry.status,
      templateType: templateType,
    );
  }

  static String _statusLabel(
    ServiceEntryStatus status,
    ServiceTemplateType templateType,
  ) {
    return switch (status) {
      ServiceEntryStatus.delivered =>
        templateType == ServiceTemplateType.attendance
            ? 'Present'
            : 'Delivered',
      ServiceEntryStatus.notDelivered =>
        templateType == ServiceTemplateType.attendance
            ? 'Absent'
            : 'Not Delivered',
      ServiceEntryStatus.halfDay => 'Half Day',
      ServiceEntryStatus.rateChanged => 'Rate Changed',
      ServiceEntryStatus.noEntry => 'No Entry',
    };
  }

  static String _formatQuantity(double quantity) {
    if (quantity.truncateToDouble() == quantity) {
      return quantity.toStringAsFixed(0);
    }
    return quantity
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
