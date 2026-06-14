import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payqure_home/common/widgets/app_logo_mark.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/app_route.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('onboarding moves through all four pages', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onComplete: () async {
            completed = true;
          },
        ),
      ),
    );

    expect(find.text('Track Household\nServices Easily'), findsOneWidget);
    final logo = tester.widget<AppLogoMark>(find.byType(AppLogoMark));
    expect(logo.size, 52);

    expect(find.text('Next'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('onboarding-page-view')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Log Daily\nDeliveries & Attendance'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('onboarding-page-view')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Know What\nYou Owe'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('onboarding-page-view')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Keep Everything\nOrganized'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('skip completes onboarding (routes to login)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onComplete: () async {
            completed = true;
          },
        ),
      ),
    );

    // Skip is available from the very first page.
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pump();
    expect(completed, isTrue);
  });

  test('onboarding completion is persisted and shown only once', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftLedgerRepository(
      database: database,
      remoteDataSource: SupabaseLedgerRemoteDataSource(null),
    );
    final firstController = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: repository,
      pdfStatementService: const PdfStatementService(),
    );
    addTearDown(firstController.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await firstController.completeSplash();
    expect(firstController.route, LedgerRoute.onboarding);

    await firstController.completeOnboarding();
    expect(firstController.route, LedgerRoute.login);

    final secondController = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: repository,
      pdfStatementService: const PdfStatementService(),
    );
    addTearDown(secondController.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await secondController.completeSplash();
    expect(secondController.route, LedgerRoute.login);
  });
}
