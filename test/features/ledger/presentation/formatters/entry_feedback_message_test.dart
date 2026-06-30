import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/utils/currency_formatter.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/formatters/entry_feedback_message.dart';

void main() {
  group('EntryFeedbackMessage', () {
    test('confirms the date update and exact amount added', () {
      final entry = _entry(
        status: ServiceEntryStatus.delivered,
        amountCents: 6000,
      );
      expect(
        EntryFeedbackMessage.statusUpdated(
          day: 29,
          monthKey: '2026-06',
          entry: entry,
        ),
        '29 Jun updated. ${CurrencyFormatter.cents(6000)} has been added to your bill.',
      );
    });

    test('shows a zero amount for a missed entry', () {
      final entry = _entry(
        status: ServiceEntryStatus.notDelivered,
        amountCents: 0,
      );
      expect(
        EntryFeedbackMessage.statusUpdated(
          day: 29,
          monthKey: '2026-06',
          entry: entry,
        ),
        '29 Jun updated. ${CurrencyFormatter.cents(0)} has been added to your bill.',
      );
    });

    test('describes the exact customized decimal quantity and unit', () {
      final entry = ServiceEntry(
        id: 'entry-1',
        serviceId: 'service-1',
        monthKey: '2026-06',
        day: 29,
        status: ServiceEntryStatus.delivered,
        quantity: 1.25,
        unit: 'L',
        rateCents: 6000,
        amountCents: 7500,
        note: '',
        updatedAt: DateTime(2026, 6, 29),
      );

      expect(
        EntryFeedbackMessage.customized(
          day: 29,
          monthKey: '2026-06',
          entry: entry,
          templateType: ServiceTemplateType.quantity,
        ),
        '29 Jun quantity has been updated to 1.25 L. '
        '${CurrencyFormatter.cents(7500)} has been added to your bill.',
      );
    });
  });
}

ServiceEntry _entry({
  required ServiceEntryStatus status,
  required int amountCents,
}) {
  return ServiceEntry(
    id: 'entry-1',
    serviceId: 'service-1',
    monthKey: '2026-06',
    day: 29,
    status: status,
    quantity: status == ServiceEntryStatus.notDelivered ? 0 : 1,
    unit: 'L',
    rateCents: 6000,
    amountCents: amountCents,
    note: '',
    updatedAt: DateTime(2026, 6, 29),
  );
}
