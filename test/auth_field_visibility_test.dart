import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/ledger/presentation/screens/login_screen.dart';

void main() {
  testWidgets('login password visibility can be toggled', (tester) async {
    final fixture = _AuthFixture();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: fixture.controller)),
    );

    EditableText passwordField() {
      return tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
    }

    expect(passwordField().obscureText, isTrue);
    expect(passwordField().scrollPadding.bottom, 120);

    await tester.tap(find.byKey(const ValueKey('password-visibility')));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);

    await tester.tap(find.byKey(const ValueKey('password-visibility')));
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('signup and reset password fields expose visibility controls', (
    tester,
  ) async {
    final fixture = _AuthFixture();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(controller: fixture.controller)),
    );
    expect(find.byKey(const ValueKey('password-visibility')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirm-password-visibility')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(home: ResetPasswordOtpScreen(controller: fixture.controller)),
    );
    expect(
      find.byKey(const ValueKey('new-password-visibility')),
      findsOneWidget,
    );
  });
}

class _AuthFixture {
  _AuthFixture() {
    database = LedgerDatabase(NativeDatabase.memory());
    authRepository = SupabaseAuthRepository(client: null);
    controller = LedgerController(
      authRepository: authRepository,
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
    );
  }

  late final LedgerDatabase database;
  late final SupabaseAuthRepository authRepository;
  late final LedgerController controller;

  Future<void> dispose() async {
    controller.dispose();
    await authRepository.dispose();
    await database.close();
  }
}
