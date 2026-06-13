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

  testWidgets('validation error clears when entered value becomes valid', (
    tester,
  ) async {
    final fixture = _AuthFixture();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: fixture.controller)),
    );

    final identifierField = find.byType(TextFormField).first;
    await tester.enterText(identifierField, 'invalid');
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);

    await tester.enterText(identifierField, 'valid@example.com');
    await tester.pump();
    expect(find.text('Enter a valid email'), findsNothing);
  });

  testWidgets(
    'registration validates only the field the user interacted with',
    (tester) async {
      final fixture = _AuthFixture();
      addTearDown(fixture.dispose);
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(controller: fixture.controller)),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Madhur');
      await tester.pump();

      expect(find.text('Enter a valid email'), findsNothing);
      expect(find.text('Enter a valid phone number'), findsNothing);
      expect(find.text('Use at least 8 characters'), findsNothing);
      expect(find.text('Passwords must match'), findsNothing);
    },
  );

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

  testWidgets('OTP confirmation email fields are read-only', (tester) async {
    final fixture = _AuthFixture();
    addTearDown(fixture.dispose);
    fixture.controller.pendingVerificationEmail = 'verify@example.com';
    fixture.controller.pendingPasswordResetEmail = 'reset@example.com';

    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationScreen(controller: fixture.controller),
      ),
    );
    var emailField = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
    );
    expect(emailField.readOnly, isTrue);
    expect(find.bySemanticsLabel('Email cannot be edited'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: ResetPasswordOtpScreen(controller: fixture.controller)),
    );
    emailField = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
    );
    expect(emailField.readOnly, isTrue);
    expect(find.bySemanticsLabel('Email cannot be edited'), findsOneWidget);
  });

  testWidgets('signup OTP resend is disabled for two minutes', (tester) async {
    final fixture = _AuthFixture();
    addTearDown(fixture.dispose);

    await fixture.controller.register(
      name: 'Madhur',
      email: 'verify@example.com',
      phone: '9876543210',
      password: 'Password1',
      privacyPolicyAccepted: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationScreen(controller: fixture.controller),
      ),
    );

    final resendButton = tester.widget<TextButton>(
      find.byKey(const ValueKey('resend-verification-otp')),
    );
    expect(resendButton.onPressed, isNull);
    expect(find.textContaining('Resend OTP in 2:'), findsOneWidget);
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
