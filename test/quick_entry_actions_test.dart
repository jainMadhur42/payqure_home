import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_colors.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/quick_entry_actions.dart';

void main() {
  testWidgets(
    'quantity quick actions use compact chips without radio controls',
    (tester) async {
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
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      final customIconBackground = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(const ValueKey('quick-entry-custom')),
              matching: find.byType(Container),
            ),
          )
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .singleWhere((decoration) => decoration.shape == BoxShape.circle);
      expect(customIconBackground.color, AppColors.warning);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('quick-entry-custom'))).dy,
        greaterThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('quick-entry-delivered')))
              .dy,
        ),
      );

      await tester.tap(find.text('Missed'));
      await tester.tap(find.text('Custom'));

      expect(selectedStatus, ServiceEntryStatus.notDelivered);
      expect(customizeTapped, isTrue);
    },
  );

  testWidgets('attendance actions do not expose quantity customization', (
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
    expect(find.text('Custom'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('quick-entry-half-day'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('quick-entry-delivered')))
            .dy,
      ),
    );
  });

  testWidgets('fixed monthly delivered entry never selects custom', (
    tester,
  ) async {
    final service = _service(
      ServiceTemplateType.fixedMonthly,
      monthlyAmountCents: 31000,
    );
    final entry = ServiceEntry(
      id: 'newspaper-entry',
      serviceId: service.id,
      day: 12,
      monthKey: service.monthKey,
      status: ServiceEntryStatus.delivered,
      quantity: 1,
      unit: 'Month',
      rateCents: 1000,
      amountCents: 31000,
      updatedAt: DateTime(2026, 6, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickEntryActionGrid(
            service: service,
            selectedEntry: entry,
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(isCustomQuickEntry(service, entry), isFalse);
    expect(find.text('Custom'), findsNothing);
    expect(_isSelected(tester, 'quick-entry-delivered'), isTrue);
  });

  test('attendance entry with a derived daily rate is not custom', () {
    final service = _service(
      ServiceTemplateType.attendance,
      monthlyAmountCents: 31000,
    );
    final entry = ServiceEntry(
      id: 'cleaning-entry',
      serviceId: service.id,
      day: 12,
      monthKey: service.monthKey,
      status: ServiceEntryStatus.delivered,
      quantity: 1,
      unit: 'Day',
      rateCents: 1000,
      amountCents: 1000,
      updatedAt: DateTime(2026, 6, 12),
    );

    expect(isCustomQuickEntry(service, entry), isFalse);
  });

  testWidgets('custom quantity remains selected and appears in chip label', (
    tester,
  ) async {
    final service = _service(ServiceTemplateType.quantity);
    final customEntry = ServiceEntry(
      id: 'custom-entry',
      serviceId: service.id,
      day: 12,
      monthKey: service.monthKey,
      status: ServiceEntryStatus.delivered,
      quantity: 2,
      unit: 'Liter',
      rateCents: service.rateCents,
      amountCents: 12000,
      updatedAt: DateTime(2026, 6, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: QuickEntryActionGrid(
              service: service,
              selectedEntry: customEntry,
              onQuickMark: (_) {},
              onCustomize: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Custom 2 L'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('quick-entry-custom')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivered immediately clears a custom selection', (
    tester,
  ) async {
    final service = _service(ServiceTemplateType.quantity);
    final customEntry = ServiceEntry(
      id: 'custom-entry',
      serviceId: service.id,
      day: 12,
      monthKey: service.monthKey,
      status: ServiceEntryStatus.delivered,
      quantity: 2,
      unit: 'L',
      rateCents: service.rateCents,
      amountCents: 12000,
      updatedAt: DateTime(2026, 6, 12),
    );
    ServiceEntryStatus? selectedStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickEntryActionCard(
            service: service,
            selectedEntry: customEntry,
            selectedStatus: customEntry.status,
            onQuickMark: (status) => selectedStatus = status,
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(_isSelected(tester, 'quick-entry-custom'), isTrue);
    expect(_isSelected(tester, 'quick-entry-delivered'), isFalse);

    await tester.tap(find.byKey(const ValueKey('quick-entry-delivered')));
    await tester.pump();

    expect(selectedStatus, ServiceEntryStatus.delivered);
    expect(_isSelected(tester, 'quick-entry-delivered'), isTrue);
    expect(_isSelected(tester, 'quick-entry-custom'), isFalse);
  });

  testWidgets('rate or unit changes do not select custom at default quantity', (
    tester,
  ) async {
    final service = _service(ServiceTemplateType.quantity);
    final rateChangedEntry = ServiceEntry(
      id: 'rate-entry',
      serviceId: service.id,
      day: 12,
      monthKey: service.monthKey,
      status: ServiceEntryStatus.rateChanged,
      quantity: service.defaultQuantity,
      unit: 'ml',
      rateCents: service.rateCents + 500,
      amountCents: service.rateCents + 500,
      updatedAt: DateTime(2026, 6, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickEntryActionGrid(
            service: service,
            selectedEntry: rateChangedEntry,
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(_isSelected(tester, 'quick-entry-delivered'), isTrue);
    expect(_isSelected(tester, 'quick-entry-custom'), isFalse);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('customize form reuses the log-entry card without no-entry', (
    tester,
  ) async {
    ServiceEntryStatus? selectedStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickEntryActionCard(
            service: _service(ServiceTemplateType.quantity),
            selectedStatus: ServiceEntryStatus.delivered,
            customSelectedOverride: true,
            onQuickMark: (status) => selectedStatus = status,
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(find.text('Log Entry'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('No Entry'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);

    await tester.tap(find.byKey(const ValueKey('quick-entry-not-delivered')));
    expect(selectedStatus, ServiceEntryStatus.notDelivered);
  });
}

bool _isSelected(WidgetTester tester, String key) {
  return tester
          .getSemantics(find.byKey(ValueKey(key)))
          .flagsCollection
          .isSelected ==
      Tristate.isTrue;
}

HouseholdService _service(
  ServiceTemplateType templateType, {
  int monthlyAmountCents = 0,
}) {
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
    monthlyAmountCents: monthlyAmountCents,
    entries: const [],
    updatedAt: DateTime(2026, 6, 1),
  );
}
