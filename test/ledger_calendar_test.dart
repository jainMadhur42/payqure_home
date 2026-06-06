import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/ledger_calendar.dart';

void main() {
  testWidgets('calendar blocks dates before the service start date', (
    tester,
  ) async {
    int? selectedDay;
    DateTime? blockedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: LedgerCalendar(
              entries: const [],
              monthKey: '2026-05',
              selectedDay: 25,
              serviceStartDate: DateTime(2026, 5, 25),
              onDaySelected: (day) => selectedDay = day,
              onBlockedDaySelected: (date) => blockedDate = date,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('24'));
    expect(blockedDate, DateTime(2026, 5, 24));
    expect(selectedDay, isNull);

    await tester.tap(find.text('25'));
    expect(selectedDay, 25);
  });
}
