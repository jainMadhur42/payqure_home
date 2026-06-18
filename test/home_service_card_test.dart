import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_colors.dart';
import 'package:payqure_home/core/theme/app_radius.dart';
import 'package:payqure_home/features/ledger/domain/entities/home_summary.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/ledger_month.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/screens/home_screen.dart';

void main() {
  testWidgets('home service card shows logged-today status border', (
    tester,
  ) async {
    final now = DateTime.now();
    final service = _service(
      entries: [
        ServiceEntry(
          id: 'entry-today',
          serviceId: 'service-1',
          day: now.day,
          monthKey: LedgerMonth.fromDate(now).key,
          status: ServiceEntryStatus.delivered,
          quantity: 1,
          unit: 'L',
          rateCents: 6000,
          amountCents: 6000,
          updatedAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeServiceCard(
            summary: _summary(service),
            onTap: () {},
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(find.text("Today's Entry"), findsOne);
    expect(find.text('1 L'), findsOne);
    expect(find.textContaining('Provider:'), findsNothing);
    expect(find.text('This Month'), findsNothing);
    expect(find.text('Quantity Based'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Milkman. Today entry logged.',
      ),
      findsOne,
    );
    expect(_hasStatusBorderColor(tester, AppColors.success), isTrue);
  });

  testWidgets('home service card shows no-entry-today status border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeServiceCard(
            summary: _summary(_service()),
            onTap: () {},
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(find.text("Today's Entry"), findsOne);
    expect(find.text('Not Logged'), findsOne);
    // No entry today → grey, matching the service detail calendar logic.
    expect(_hasStatusBorderColor(tester, AppColors.muted), isTrue);
  });

  testWidgets('home service card shows attendance status for today', (
    tester,
  ) async {
    final now = DateTime.now();
    final service = _service(
      templateType: ServiceTemplateType.attendance,
      icon: 'maid',
      entries: [
        ServiceEntry(
          id: 'entry-today',
          serviceId: 'service-1',
          day: now.day,
          monthKey: LedgerMonth.fromDate(now).key,
          status: ServiceEntryStatus.delivered,
          quantity: 1,
          unit: 'Day',
          rateCents: 35000,
          amountCents: 35000,
          updatedAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeServiceCard(
            summary: _summary(service),
            onTap: () {},
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(find.text("Today's Entry"), findsOne);
    expect(find.text('Present'), findsOne);
  });

  testWidgets('home service card shows fixed monthly billed state', (
    tester,
  ) async {
    final service = _service(
      name: 'Newspaper',
      icon: 'news',
      templateType: ServiceTemplateType.fixedMonthly,
      monthlyAmountCents: 18000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeServiceCard(
            summary: _summary(service),
            onTap: () {},
            onQuickMark: (_) {},
            onCustomize: () {},
          ),
        ),
      ),
    );

    expect(find.text("Today's Entry"), findsOne);
    expect(find.text('Billed This Month'), findsOne);
  });
}

bool _hasStatusBorderColor(WidgetTester tester, Color color) {
  final containers = tester.widgetList<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  return containers.any((container) {
    final decoration = container.decoration;
    return decoration is BoxDecoration &&
        decoration.color == color &&
        decoration.borderRadius ==
            const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
            );
  });
}

HomeServiceSummary _summary(HouseholdService service) {
  return HomeServiceSummary(
    service: service,
    metricLabel: '1 L this month',
    payableCents: 6000,
    paidCents: 0,
    remainingCents: 6000,
    advanceCents: 0,
    usageCents: 6000,
    previousPendingCents: 0,
    advanceUsedCents: 0,
    deliveredDays: 1,
    missedDays: 0,
    totalQuantity: 1,
    statusLabel: 'Pending',
    primaryLabel: 'Due till today',
    primaryAmountCents: 6000,
  );
}

HouseholdService _service({
  String name = 'Milkman',
  String icon = 'milkman',
  ServiceTemplateType templateType = ServiceTemplateType.quantity,
  int monthlyAmountCents = 0,
  List<ServiceEntry> entries = const [],
}) {
  final now = DateTime.now();
  return HouseholdService(
    id: 'service-1',
    userId: 'user-1',
    name: name,
    description: 'Provider: Ramesh',
    icon: icon,
    templateType: templateType,
    monthKey: LedgerMonth.fromDate(now).key,
    unit: templateType == ServiceTemplateType.quantity ? 'L' : 'Day',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: monthlyAmountCents,
    entries: entries,
    updatedAt: now,
  );
}
