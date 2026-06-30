import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/quick_log_horizontal_calendar.dart';

void main() {
  testWidgets('quick log calendar selects days and marks complete days', (
    tester,
  ) async {
    DateTime? selectedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickLogHorizontalCalendar(
            monthKey: '2026-06',
            selectedDate: DateTime(2026, 6, 27),
            today: DateTime(2026, 6, 27),
            services: [
              _service(
                'milk',
                entries: [_entry('milk', 26, ServiceEntryStatus.delivered)],
              ),
              _service(
                'maid',
                entries: [_entry('maid', 26, ServiceEntryStatus.notDelivered)],
              ),
            ],
            onDateSelected: (date) => selectedDate = date,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JUN 2026'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('quick-log-day-complete-26')),
      findsOneWidget,
    );

    await tester.tap(find.text('26'));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(2026, 6, 26));

    selectedDate = null;
    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();

    expect(selectedDate, isNull);
  });

  testWidgets('today animation does not change calendar size', (tester) async {
    var selectedDate = DateTime(2026, 6, 27);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => QuickLogHorizontalCalendar(
              key: const ValueKey('quick-log-calendar'),
              monthKey: '2026-06',
              selectedDate: selectedDate,
              today: DateTime(2026, 6, 27),
              services: const [],
              onDateSelected: (date) => setState(() => selectedDate = date),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final calendar = find.byKey(const ValueKey('quick-log-calendar'));
    final initialSize = tester.getSize(calendar);
    expect(find.byKey(const ValueKey('quick-log-today')), findsNothing);

    await tester.tap(find.text('26'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-log-today')), findsOneWidget);
    expect(tester.getSize(calendar), initialSize);

    await tester.tap(find.byKey(const ValueKey('quick-log-today')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-log-today')), findsNothing);
    expect(tester.getSize(calendar), initialSize);
  });

  testWidgets('calendar fits complete day items without clipped edge labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: QuickLogHorizontalCalendar(
                key: const ValueKey('quick-log-calendar'),
                monthKey: '2026-06',
                selectedDate: DateTime(2026, 6, 27),
                today: DateTime(2026, 6, 27),
                services: const [],
                onDateSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final calendarRect = tester.getRect(
      find.byKey(const ValueKey('quick-log-calendar')),
    );
    final firstVisibleRect = tester.getRect(
      find.byKey(const ValueKey('quick-log-day-24')),
    );
    final lastVisibleRect = tester.getRect(
      find.byKey(const ValueKey('quick-log-day-30')),
    );

    expect(firstVisibleRect.left, greaterThanOrEqualTo(calendarRect.left));
    expect(lastVisibleRect.right, lessThanOrEqualTo(calendarRect.right));
    expect(find.text('Wed'), findsOneWidget);
  });
}

HouseholdService _service(String id, {required List<ServiceEntry> entries}) {
  return HouseholdService(
    id: id,
    userId: 'user',
    name: id,
    description: '',
    icon: 'milk',
    templateType: ServiceTemplateType.quantity,
    monthKey: '2026-06',
    unit: 'Liter',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: entries,
    updatedAt: DateTime(2026, 6, 1),
  );
}

ServiceEntry _entry(String serviceId, int day, ServiceEntryStatus status) {
  return ServiceEntry(
    id: '$serviceId-$day',
    serviceId: serviceId,
    day: day,
    monthKey: '2026-06',
    status: status,
    quantity: 1,
    unit: 'Liter',
    rateCents: 6000,
    amountCents: status == ServiceEntryStatus.notDelivered ? 0 : 6000,
    updatedAt: DateTime(2026, 6, day),
  );
}
