import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_colors.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/ledger_calendar.dart';

void main() {
  testWidgets('calendar leaves unselected no-entry dates transparent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: LedgerCalendar(
              entries: const [],
              monthKey: '2026-05',
              selectedDay: 2,
              onDaySelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final cell = find.byKey(
      const ValueKey('calendar-day-2026-05-01T00:00:00.000'),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, Colors.transparent);
    expect(decoration.border, isNull);
  });

  testWidgets(
    'calendar circles a selected no-entry date and shows status dot',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: AppColors.primary),
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: LedgerCalendar(
                entries: const [],
                monthKey: '2026-05',
                selectedDay: 1,
                onDaySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final cell = find.byKey(
        const ValueKey('calendar-day-2026-05-01T00:00:00.000'),
      );
      final container = tester.widget<AnimatedContainer>(
        find.descendant(of: cell, matching: find.byType(AnimatedContainer)),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(
        decoration.color,
        Theme.of(tester.element(cell)).colorScheme.primary,
      );
      expect(
        find.byKey(
          const ValueKey('calendar-selected-status-2026-05-01T00:00:00.000'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('selected date dot uses its delivery status color', (
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
              selectedDay: 2,
              onDaySelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final dot = tester.widget<Container>(
      find.byKey(
        const ValueKey('calendar-selected-status-2026-05-02T00:00:00.000'),
      ),
    );
    final decoration = dot.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.success);
  });

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

  testWidgets('calendar blocks future dates from entry logging', (
    tester,
  ) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final monthKey =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}';
    int? selectedDay;
    DateTime? blockedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: LedgerCalendar(
              entries: const [],
              monthKey: monthKey,
              selectedDay: tomorrow.day,
              onDaySelected: (day) => selectedDay = day,
              onBlockedDaySelected: (date) => blockedDate = date,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-day-${DateTime(tomorrow.year, tomorrow.month, tomorrow.day).toIso8601String()}',
        ),
      ),
    );
    expect(blockedDate, DateTime(tomorrow.year, tomorrow.month, tomorrow.day));
    expect(selectedDay, isNull);
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

    expect(decoration.color, AppColors.warning.withValues(alpha: 0.10));
    expect(decoration.shape, BoxShape.circle);
  });
}
