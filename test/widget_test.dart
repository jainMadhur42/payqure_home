import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payqure_home/app.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/ledger/presentation/screens/splash_screen.dart';
import 'package:payqure_home/core/theme/app_theme.dart';

void main() {
  testWidgets('App shows service ledger splash screen', (
    WidgetTester tester,
  ) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(PayqureHomeApp(database: database));

    expect(find.text('Daily Service Ledger'), findsOneWidget);
    expect(
      find.text('Track daily services. Settle monthly bills easily.'),
      findsOneWidget,
    );
  });

  testWidgets('Splash follows dark theme colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: SplashScreen(onDone: () {}),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('splash-background')),
    );
    final decoration = container.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors.first, const Color(0xFF101117));
    expect(
      tester.widget<Text>(find.text('Daily Service Ledger')).style?.color,
      AppTheme.dark.colorScheme.onSurface,
    );
  });

  testWidgets('Splash opens dashboard with dev bypass', (
    WidgetTester tester,
  ) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(PayqureHomeApp(database: database));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Dev Bypass Login'));
    await tester.pumpAndSettle();

    expect(find.text('Payqure Home'), findsOneWidget);
    expect(find.text('Amount Due'), findsOneWidget);
  });

  test('Controller can switch months', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
    );
    addTearDown(controller.dispose);

    await controller.signIn(
      identifier: 'local@payqure.local',
      password: 'password123',
    );

    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final nextMonth = DateTime(now.year, now.month + 1);
    final nextMonthKey =
        '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';

    expect(controller.monthKey, currentMonthKey);
    expect(controller.overview?.services, isEmpty);

    await controller.goToNextMonth();

    expect(controller.monthKey, nextMonthKey);
    expect(controller.overview?.services, isEmpty);
  });

  test('Controller persists selected theme mode', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftLedgerRepository(
      database: database,
      remoteDataSource: SupabaseLedgerRemoteDataSource(null),
    );
    final controller = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: repository,
      pdfStatementService: const PdfStatementService(),
    );
    addTearDown(controller.dispose);

    await controller.selectThemeMode(ThemeMode.dark);

    final restoredController = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: repository,
      pdfStatementService: const PdfStatementService(),
    );
    addTearDown(restoredController.dispose);
    await restoredController.restoreThemePreference();

    expect(restoredController.selectedThemeMode, ThemeMode.dark);
  });
}
