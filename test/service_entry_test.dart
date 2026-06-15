import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';

void main() {
  test('quantity label separates quantity and unit', () {
    final entry = ServiceEntry(
      id: 'entry-1',
      serviceId: 'service-1',
      day: 14,
      monthKey: '2026-06',
      status: ServiceEntryStatus.delivered,
      quantity: 3.5,
      unit: 'liter',
      rateCents: 6000,
      amountCents: 21000,
      updatedAt: DateTime(2026, 6, 14),
    );

    expect(entry.quantityLabel, '3.5 liter');
  });

  test('quantity label trims stored unit whitespace', () {
    final entry = ServiceEntry(
      id: 'entry-1',
      serviceId: 'service-1',
      day: 14,
      monthKey: '2026-06',
      status: ServiceEntryStatus.delivered,
      quantity: 1,
      unit: ' L ',
      rateCents: 6000,
      amountCents: 6000,
      updatedAt: DateTime(2026, 6, 14),
    );

    expect(entry.quantityLabel, '1 L');
  });
}
