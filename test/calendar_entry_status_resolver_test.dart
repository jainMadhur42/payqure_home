import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/services/calendar_entry_status_resolver.dart';

void main() {
  ServiceEntry entry({
    ServiceEntryStatus status = ServiceEntryStatus.delivered,
    double quantity = 1,
  }) {
    return ServiceEntry(
      id: 'entry-1',
      serviceId: 'service-1',
      day: 12,
      monthKey: '2026-06',
      status: status,
      quantity: quantity,
      unit: 'L',
      rateCents: 6000,
      amountCents: 6000,
      updatedAt: DateTime(2026, 6, 12),
    );
  }

  test('uses quantity-changed visual status when quantity differs', () {
    final status = CalendarEntryStatusResolver.resolve(
      entry: entry(quantity: 1),
      configuredQuantity: 0.5,
    );

    expect(status, CalendarEntryVisualStatus.quantityChanged);
  });

  test('uses delivered visual status when quantity matches', () {
    final status = CalendarEntryStatusResolver.resolve(
      entry: entry(quantity: 0.5),
      configuredQuantity: 0.5,
    );

    expect(status, CalendarEntryVisualStatus.delivered);
  });

  test('maps all stored entry statuses to shared calendar statuses', () {
    expect(
      CalendarEntryStatusResolver.resolve(entry: null),
      CalendarEntryVisualStatus.noEntry,
    );
    expect(
      CalendarEntryStatusResolver.resolve(
        entry: entry(status: ServiceEntryStatus.notDelivered, quantity: 0),
      ),
      CalendarEntryVisualStatus.notDelivered,
    );
    expect(
      CalendarEntryStatusResolver.resolve(
        entry: entry(status: ServiceEntryStatus.rateChanged),
      ),
      CalendarEntryVisualStatus.quantityChanged,
    );
    expect(
      CalendarEntryStatusResolver.resolve(
        entry: entry(status: ServiceEntryStatus.halfDay, quantity: 0.5),
      ),
      CalendarEntryVisualStatus.quantityChanged,
    );
  });
}
