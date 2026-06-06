import '../../../../core/utils/currency_formatter.dart';
import '../entities/household_service.dart';
import '../entities/service_entry.dart';
import '../entities/service_template.dart';

class EntryAmountBreakdown {
  const EntryAmountBreakdown({required this.amountCents, required this.detail});

  final int amountCents;
  final String detail;
}

class EntryAmountCalculator {
  const EntryAmountCalculator();

  EntryAmountBreakdown calculate({
    required HouseholdService service,
    required ServiceEntryStatus status,
    required double quantity,
    required int rateCents,
  }) {
    if (status == ServiceEntryStatus.noEntry ||
        status == ServiceEntryStatus.notDelivered) {
      return const EntryAmountBreakdown(amountCents: 0, detail: 'No charge');
    }

    if (service.templateType == ServiceTemplateType.attendance) {
      final amount = status == ServiceEntryStatus.halfDay
          ? (rateCents / 2).round()
          : rateCents;
      return EntryAmountBreakdown(
        amountCents: amount,
        detail: status == ServiceEntryStatus.halfDay
            ? 'Half day x ${_money(rateCents)}'
            : '1 day x ${_money(rateCents)}',
      );
    }

    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      return EntryAmountBreakdown(
        amountCents: rateCents,
        detail: rateCents == 0 ? 'Included in monthly amount' : '1 day charge',
      );
    }

    final amount = (quantity * rateCents).round();
    return EntryAmountBreakdown(
      amountCents: amount,
      detail:
          '${_quantity(quantity)} ${service.unit.isEmpty ? 'unit' : service.unit} x ${_money(rateCents)}',
    );
  }

  static String _money(int cents) {
    final amount = cents / 100;
    return CurrencyFormatter.compact(amount);
  }

  static String _quantity(double quantity) {
    return quantity.toStringAsFixed(
      quantity.truncateToDouble() == quantity ? 0 : 1,
    );
  }
}
