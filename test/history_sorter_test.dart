import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_transaction.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_history_item.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/services/history_sorter.dart';

void main() {
  test('payment history sorts by payment date from latest to oldest', () {
    final payments = [
      _payment('may-payment', DateTime(2026, 5, 31)),
      _payment('june-payment', DateTime(2026, 6, 12)),
      _payment('april-payment', DateTime(2026, 4, 30)),
    ];

    expect(HistorySorter.paymentsNewestFirst(payments).map((item) => item.id), [
      'june-payment',
      'may-payment',
      'april-payment',
    ]);
  });

  test('global payment and advance history sorts newest first', () {
    final service = _service();
    final items = [
      _history('older', service, DateTime(2026, 5, 10)),
      _history('latest', service, DateTime(2026, 6, 10)),
      _history('oldest', service, DateTime(2026, 4, 10)),
    ];

    expect(HistorySorter.itemsNewestFirst(items).map((item) => item.id), [
      'latest',
      'older',
      'oldest',
    ]);
  });
}

PaymentTransaction _payment(String id, DateTime date) {
  return PaymentTransaction(
    id: id,
    userId: 'user',
    serviceId: 'service',
    monthKey: '2026-05',
    amountCents: 10000,
    paymentDate: date,
    mode: PaymentMode.cash,
    updatedAt: date,
  );
}

ServiceHistoryItem _history(
  String id,
  HouseholdService service,
  DateTime date,
) {
  return ServiceHistoryItem(
    id: id,
    service: service,
    type: ServiceHistoryType.advance,
    amountCents: 10000,
    date: date,
    modeLabel: 'Advance',
    note: '',
    pendingSync: false,
  );
}

HouseholdService _service() {
  return HouseholdService(
    id: 'service',
    userId: 'user',
    name: 'Milkman',
    description: '',
    icon: 'milk',
    templateType: ServiceTemplateType.quantity,
    monthKey: '2026-06',
    unit: 'L',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: const [],
    updatedAt: DateTime(2026, 6),
  );
}
