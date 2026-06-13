import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/quick_entry_actions.dart';

void main() {
  testWidgets('quantity quick actions use buttons without radio controls', (
    tester,
  ) async {
    ServiceEntryStatus? selectedStatus;
    var customizeTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickEntryActionGrid(
            service: _service(ServiceTemplateType.quantity),
            selectedStatus: ServiceEntryStatus.delivered,
            onQuickMark: (status) => selectedStatus = status,
            onCustomize: () => customizeTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Not Delivered'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);

    await tester.tap(find.text('Not Delivered'));
    await tester.tap(find.text('Customize'));

    expect(selectedStatus, ServiceEntryStatus.notDelivered);
    expect(customizeTapped, isTrue);
  });

  testWidgets('attendance quick actions use a two by two action set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickEntryActionGrid(
            service: _service(ServiceTemplateType.attendance),
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.text('Half Day'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
  });
}

HouseholdService _service(ServiceTemplateType templateType) {
  return HouseholdService(
    id: 'service',
    userId: 'user',
    name: 'Service',
    description: '',
    icon: 'service',
    templateType: templateType,
    monthKey: '2026-06',
    unit: templateType == ServiceTemplateType.attendance ? 'Day' : 'L',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: const [],
    updatedAt: DateTime(2026, 6, 1),
  );
}
