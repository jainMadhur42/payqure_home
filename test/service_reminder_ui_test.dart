import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/common/widgets/app_switch.dart';
import 'package:payqure_home/core/theme/app_theme.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_metadata.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/screens/notifications_screen.dart';
import 'package:payqure_home/features/ledger/presentation/screens/service_detail_screen.dart';

void main() {
  final service = HouseholdService(
    id: 'milk',
    userId: 'user',
    name: 'Milkman',
    description: ServiceMetadata(
      serviceTime: '8:30 AM',
      remindBeforeMinutes: 15,
      startDate: DateTime(2026, 6, 1),
    ).encode(),
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

  testWidgets('notification card shows schedule and toggle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ServiceNotificationCard(
            service: service,
            onToggle: (_) {},
            onEdit: () {},
          ),
        ),
      ),
    );

    expect(find.text('Milkman'), findsOneWidget);
    expect(find.textContaining('Daily at 8:15 AM'), findsOneWidget);
    expect(find.byType(AppSwitch), findsOneWidget);
    final switchWidget = tester.widget<Switch>(
      find.descendant(
        of: find.byType(AppSwitch),
        matching: find.byType(Switch),
      ),
    );
    expect(switchWidget.activeTrackColor, AppTheme.light().colorScheme.primary);
    expect(find.text('Change time'), findsOneWidget);
  });

  testWidgets('service detail reminder card exposes schedule controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: ServiceReminderDetailCard(
            service: service,
            onToggle: (_) {},
            onEdit: () {},
          ),
        ),
      ),
    );

    expect(find.text('Service Reminder'), findsOneWidget);
    expect(find.text('8:30 AM · 15 minutes before'), findsOneWidget);
    expect(find.byType(AppSwitch), findsOneWidget);
    final switchWidget = tester.widget<Switch>(
      find.descendant(
        of: find.byType(AppSwitch),
        matching: find.byType(Switch),
      ),
    );
    expect(switchWidget.activeTrackColor, AppTheme.dark().colorScheme.primary);
    expect(find.text('Change time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
