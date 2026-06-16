import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payqure_home/app.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/services/local_notification_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/app_route.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_transaction.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_metadata.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/ledger/presentation/screens/login_screen.dart';
import 'package:payqure_home/features/ledger/presentation/screens/splash_screen.dart';
import 'package:payqure_home/core/theme/app_theme.dart';

void main() {
  testWidgets('App shows service ledger splash screen', (
    WidgetTester tester,
  ) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(PayqureHomeApp(database: database));

    expect(find.text('Payqure Home'), findsOneWidget);
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
      tester.widget<Text>(find.text('Payqure Home')).style?.color,
      AppTheme.dark.colorScheme.onSurface,
    );
  });

  testWidgets('Login does not expose developer bypass', (
    WidgetTester tester,
  ) async {
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

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: controller)),
    );
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Dev Bypass Login'), findsNothing);
  });

  test('Controller exposes only valid month filters', () async {
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
    expect(controller.availableMonthKeys, [currentMonthKey]);

    await controller.goToNextMonth();

    expect(controller.monthKey, currentMonthKey);
    expect(controller.availableMonthKeys, isNot(contains(nextMonthKey)));
  });

  test('Controller month filters start from earliest service month', () async {
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
    final startDate = DateTime(now.year, now.month - 2, 5);
    final startMonthKey =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
    final previousMonth = DateTime(startDate.year, startDate.month - 1);
    final previousMonthKey =
        '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
    final futureMonth = DateTime(now.year, now.month + 1);
    final futureMonthKey =
        '${futureMonth.year}-${futureMonth.month.toString().padLeft(2, '0')}';

    await controller.createService(
      startMonthKey: startMonthKey,
      name: 'Milkman',
      description: ServiceMetadata(
        providerName: 'Ramesh',
        startDate: startDate,
      ).encode(),
      icon: 'milkman',
      templateType: ServiceTemplateType.quantity,
      unit: 'liter',
      defaultQuantity: 1,
      rateCents: 6000,
      monthlyAmountCents: 0,
      routeAfterSave: LedgerRoute.dashboard,
    );
    await controller.refreshSelectedMonth();

    expect(controller.availableMonthKeys.first, startMonthKey);
    expect(controller.availableMonthKeys.last, currentMonthKey);
    expect(controller.availableMonthKeys.length, lessThanOrEqualTo(12));
    expect(controller.availableMonthKeys, isNot(contains(previousMonthKey)));
    expect(controller.availableMonthKeys, isNot(contains(futureMonthKey)));

    await controller.selectMonth(startMonthKey);

    expect(controller.monthKey, startMonthKey);

    await controller.goToPreviousMonth();

    expect(controller.monthKey, startMonthKey);

    await controller.selectMonth(futureMonthKey);

    expect(controller.monthKey, startMonthKey);
    expect(controller.overview?.services.map((service) => service.name), [
      'Milkman',
    ]);
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

  test('notification tap opens its service from a different month', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final scheduler = _FakeReminderScheduler();
    final controller = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
      reminderScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    addTearDown(scheduler.dispose);

    await controller.signIn(
      identifier: 'local@payqure.local',
      password: 'password123',
    );
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 5);
    final previousMonthKey =
        '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
    await controller.createService(
      startMonthKey: previousMonthKey,
      name: 'Milkman',
      description: ServiceMetadata(startDate: previousMonth).encode(),
      icon: 'milkman',
      templateType: ServiceTemplateType.quantity,
      unit: 'L',
      defaultQuantity: 1,
      rateCents: 6000,
      monthlyAmountCents: 0,
      routeAfterSave: LedgerRoute.dashboard,
    );
    final serviceId = controller.selectedService!.id;

    await controller.goToPreviousMonth();
    expect(controller.monthKey, isNot(LedgerController.defaultMonthKey()));

    scheduler.tap(serviceId);
    await _waitFor(
      () =>
          controller.route == LedgerRoute.calendar &&
          controller.selectedService?.id == serviceId,
    );

    expect(controller.monthKey, LedgerController.defaultMonthKey());
    expect(controller.route, LedgerRoute.calendar);
    expect(controller.selectedService?.id, serviceId);
  });

  test('global payment history ignores selected month filter', () async {
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
    final previousMonth = DateTime(now.year, now.month - 1, 5);
    final previousMonthKey =
        '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await controller.createService(
      startMonthKey: previousMonthKey,
      name: 'Maid',
      description: ServiceMetadata(startDate: previousMonth).encode(),
      icon: 'maid',
      templateType: ServiceTemplateType.attendance,
      unit: 'Day',
      defaultQuantity: 1,
      rateCents: 300000,
      monthlyAmountCents: 300000,
      routeAfterSave: LedgerRoute.dashboard,
    );
    await controller.createService(
      startMonthKey: currentMonthKey,
      name: 'Milkman',
      description: ServiceMetadata(startDate: now).encode(),
      icon: 'milkman',
      templateType: ServiceTemplateType.quantity,
      unit: 'L',
      defaultQuantity: 1,
      rateCents: 6000,
      monthlyAmountCents: 0,
      routeAfterSave: LedgerRoute.dashboard,
    );

    await controller.savePayment(
      amountCents: 100000,
      paymentDate: now,
      mode: PaymentMode.upi,
      returnRoute: LedgerRoute.dashboard,
    );
    await controller.savePayment(
      amountCents: 200000,
      paymentDate: now.add(const Duration(days: 1)),
      mode: PaymentMode.cash,
      returnRoute: LedgerRoute.dashboard,
    );
    await controller.refreshSelectedMonth();
    await controller.selectMonth(previousMonthKey);

    final history = await controller.loadGlobalPaymentHistory();

    expect(controller.monthKey, previousMonthKey);
    expect(history.map((item) => item.service.name), ['Milkman']);
    expect(history.map((item) => item.amountCents), [100000]);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

class _FakeReminderScheduler implements ServiceReminderScheduler {
  final StreamController<String> _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get serviceReminderTaps => _taps.stream;

  void tap(String serviceId) => _taps.add(serviceId);

  Future<void> dispose() => _taps.close();

  @override
  Future<void> cancelServiceReminders() async {}

  @override
  Future<String?> consumeLaunchServiceId() async => null;

  @override
  Future<bool> notificationsEnabled() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleServices(List<HouseholdService> services) async {}
}
