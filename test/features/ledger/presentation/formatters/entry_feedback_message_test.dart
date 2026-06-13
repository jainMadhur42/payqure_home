import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/formatters/entry_feedback_message.dart';

void main() {
  group('EntryFeedbackMessage', () {
    test('describes quantity status changes', () {
      expect(
        EntryFeedbackMessage.statusUpdated(
          day: 29,
          status: ServiceEntryStatus.notDelivered,
          templateType: ServiceTemplateType.quantity,
        ),
        '29 has been marked as Not Delivered.',
      );
    });

    test('uses attendance labels for attendance services', () {
      expect(
        EntryFeedbackMessage.statusUpdated(
          day: 29,
          status: ServiceEntryStatus.delivered,
          templateType: ServiceTemplateType.attendance,
        ),
        '29 has been marked as Present.',
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
          entry: entry,
          templateType: ServiceTemplateType.quantity,
        ),
        '29 quantity has been updated to 1.25 L.',
      );
    });
  });
}
