import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

abstract final class EntryFeedbackMessage {
  static String statusUpdated({
    required int day,
    required String monthKey,
    required ServiceEntry entry,
  }) {
    return '${_dateLabel(day, monthKey)} updated. '
        '${CurrencyFormatter.cents(entry.amountCents)} has been added to your bill.';
  }

  static String customized({
    required int day,
    required String monthKey,
    required ServiceEntry entry,
    required ServiceTemplateType templateType,
  }) {
    if (templateType == ServiceTemplateType.quantity &&
        entry.status == ServiceEntryStatus.delivered) {
      final unit = entry.unit.trim();
      final quantity = _formatQuantity(entry.quantity);
      return '${_dateLabel(day, monthKey)} quantity has been updated to '
          '$quantity${unit.isEmpty ? '' : ' $unit'}. '
          '${CurrencyFormatter.cents(entry.amountCents)} has been added to your bill.';
    }
    return statusUpdated(
      day: day,
      monthKey: monthKey,
      entry: entry,
    );
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

  static String _dateLabel(int day, String monthKey) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = LedgerMonth.parse(monthKey).month;
    return '$day ${months[(month - 1).clamp(0, 11)]}';
  }
}
