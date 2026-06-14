import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_theme.dart';
import 'package:payqure_home/features/ledger/domain/entities/home_summary.dart';
import 'package:payqure_home/features/ledger/presentation/screens/home_screen.dart';

void main() {
  const summary = HomeMonthlySummary(
    totalDueCents: 2118000,
    usageCents: 2030000,
    previousPendingCents: 88000,
    paidCents: 0,
    advanceCents: 0,
    serviceCount: 6,
  );

  for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
    testWidgets('hero summary remains readable on a small phone', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: HomeHeroSummaryCard(summary: summary),
            ),
          ),
        ),
      );

      expect(find.text('Amount Due'), findsOneWidget);
      expect(find.text('This month Charges'), findsOneWidget);
      expect(find.text('Previous Balance'), findsOneWidget);
      expect(find.text('Advance balance'), findsOneWidget);
      expect(find.text('Paid this month'), findsOneWidget);
      expect(find.text('6 Active Services'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hero-floating-service-icons')),
        findsOneWidget,
      );
      expect(find.byType(FloatingHeroIcon), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  }
}
