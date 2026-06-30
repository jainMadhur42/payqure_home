import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/utils/currency_formatter.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/screens/service_detail_screen.dart';

void main() {
  testWidgets('selected day shows quantity rate and total without status', (
    tester,
  ) async {
    final service = _service();
    final entry = ServiceEntry(
      id: 'entry',
      serviceId: service.id,
      day: 12,
      monthKey: service.monthKey,
      status: ServiceEntryStatus.delivered,
      quantity: 1,
      unit: 'L',
      rateCents: 6000,
      amountCents: 6000,
      updatedAt: DateTime(2026, 6, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectedDayDetailCard(
            day: 12,
            monthKey: service.monthKey,
            service: service,
            entry: entry,
          ),
        ),
      ),
    );

    expect(find.text('Current Status'), findsNothing);
    expect(find.text('Status'), findsNothing);
    expect(find.text('Delivered'), findsNothing);
    expect(
      find.text(
        '1 L × ${CurrencyFormatter.cents(6000)} = ${CurrencyFormatter.cents(6000)}',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('selected day without entry shows a zero calculation', (
    tester,
  ) async {
    final service = _service();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectedDayDetailCard(
            day: 12,
            monthKey: service.monthKey,
            service: service,
            entry: null,
          ),
        ),
      ),
    );

    expect(find.text('Current Status'), findsNothing);
    expect(find.text('Status'), findsNothing);
    expect(find.text('No Entry'), findsNothing);
    expect(
      find.text(
        '0 L × ${CurrencyFormatter.cents(6000)} = ${CurrencyFormatter.cents(0)}',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });
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
    updatedAt: DateTime(2026, 6, 1),
  );
}
