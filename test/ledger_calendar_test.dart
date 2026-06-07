import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_colors.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
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

  testWidgets('calendar highlights quantity differing from service default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: LedgerCalendar(
              entries: [
                ServiceEntry(
                  id: 'entry-1',
                  serviceId: 'service-1',
                  day: 2,
                  monthKey: '2026-05',
                  status: ServiceEntryStatus.delivered,
                  quantity: 1,
                  unit: 'L',
                  rateCents: 6000,
                  amountCents: 6000,
                  updatedAt: DateTime(2026, 5, 2),
                ),
              ],
              monthKey: '2026-05',
              configuredQuantity: 0.5,
              selectedDay: 1,
              onDaySelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final cell = find.byKey(
      const ValueKey('calendar-day-2026-05-02T00:00:00.000'),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.warningSoft);
  });
}
