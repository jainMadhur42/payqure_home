import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payqure_home/core/utils/currency_formatter.dart';
import 'package:payqure_home/features/legal/domain/legal_content.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/app_route.dart';
import 'package:payqure_home/features/ledger/domain/entities/user_profile.dart';
import 'package:payqure_home/features/ledger/domain/repositories/auth_repository.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/ledger/presentation/screens/ledger_home_screen.dart';
import 'package:payqure_home/features/ledger/presentation/screens/login_screen.dart';

void main() {
  test('privacy policy and terms use the canonical support email', () {
    final privacyContact = LegalContent.privacyPolicy.firstWhere(
      (section) => section.title == 'Contact Us',
    );
    final termsContact = LegalContent.termsDisclaimer.firstWhere(
      (section) => section.title == 'Contact Us',
    );

    expect(privacyContact.body, contains(LegalContent.supportEmail));
    expect(termsContact.body, contains(LegalContent.supportEmail));
  });

  testWidgets('registration stays disabled until privacy policy is accepted', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = _controller(
      database: database,
      authRepository: SupabaseAuthRepository(client: null),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('register-submit')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('signup-privacy-checkbox')));
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('register-submit')))
          .onPressed,
      isNotNull,
    );
  });

  test('privacy acceptance persists the current policy version', () async {
    final repository = SupabaseAuthRepository(client: null);
    addTearDown(repository.dispose);
    await repository.register(
      name: 'Test User',
      email: 'test@example.com',
      phone: '+919999999999',
      password: 'password123',
      privacyPolicyAccepted: false,
    );

    final profile = await repository.acceptPrivacyPolicy(
      version: LegalContent.policyVersion,
    );

    expect(profile.privacyPolicyAccepted, isTrue);
    expect(profile.privacyPolicyAcceptedAt, isNotNull);
    expect(profile.privacyPolicyVersion, LegalContent.policyVersion);
  });

  test('an old policy version opens the acceptance gate', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final authRepository = _RestoringAuthRepository(
      const UserProfile(
        id: 'remote-user',
        name: 'Test User',
        email: 'test@example.com',
        phone: '+919999999999',
        emailVerified: true,
        privacyPolicyAccepted: true,
        privacyPolicyVersion: '2025-01',
      ),
    );
    final controller = _controller(
      database: database,
      authRepository: authRepository,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await controller.completeOnboarding();
    await controller.completeSplash();

    expect(controller.route, LedgerRoute.privacyPolicyAcceptance);

    controller.goTo(LedgerRoute.dashboard);

    expect(controller.route, LedgerRoute.privacyPolicyAcceptance);
  });

  test('missing privacy acceptance blocks ledger routes', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final authRepository = _RestoringAuthRepository(
      const UserProfile(
        id: 'remote-user',
        name: 'Test User',
        email: 'test@example.com',
        phone: '+919999999999',
        emailVerified: true,
        privacyPolicyAccepted: false,
        privacyPolicyVersion: '',
      ),
    );
    final controller = _controller(
      database: database,
      authRepository: authRepository,
    );
    addTearDown(controller.dispose);

    await controller.completeOnboarding();
    await controller.completeSplash();

    expect(controller.route, LedgerRoute.privacyPolicyAcceptance);

    controller.goTo(LedgerRoute.more);

    expect(controller.route, LedgerRoute.privacyPolicyAcceptance);
  });

  test('accepting the latest privacy policy unlocks the ledger', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final authRepository = _RestoringAuthRepository(
      const UserProfile(
        id: 'remote-user',
        name: 'Test User',
        email: 'test@example.com',
        phone: '+919999999999',
        emailVerified: true,
        privacyPolicyAccepted: true,
        privacyPolicyVersion: '2025-01',
      ),
    );
    final controller = _controller(
      database: database,
      authRepository: authRepository,
    );
    addTearDown(controller.dispose);

    await controller.completeOnboarding();
    await controller.completeSplash();
    await controller.acceptPrivacyPolicy();

    expect(authRepository.currentProfile?.privacyPolicyAccepted, isTrue);
    expect(
      authRepository.currentProfile?.privacyPolicyVersion,
      LegalContent.policyVersion,
    );
    expect(controller.route, LedgerRoute.dashboard);
  });

  test(
    'session restoration failure exits splash instead of loading forever',
    () async {
      final database = LedgerDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _controller(
        database: database,
        authRepository: _RestoringAuthRepository(
          const UserProfile(
            id: 'remote-user',
            name: 'Test User',
            email: 'test@example.com',
            phone: '',
            emailVerified: true,
          ),
          failRestore: true,
        ),
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.completeOnboarding();
      await controller.completeSplash();

      expect(controller.route, LedgerRoute.login);
      expect(controller.isLoading, isFalse);
    },
  );

  test('session restoration applies the saved profile currency', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final authRepository = _RestoringAuthRepository(
      const UserProfile(
        id: 'remote-user',
        name: 'Test User',
        email: 'test@example.com',
        phone: '+919999999999',
        emailVerified: true,
        privacyPolicyAccepted: true,
        privacyPolicyVersion: LegalContent.policyVersion,
        preferredCurrencyCode: 'INR',
      ),
    );
    final controller = _controller(
      database: database,
      authRepository: authRepository,
    );
    addTearDown(controller.dispose);

    await controller.completeOnboarding();
    await controller.completeSplash();

    expect(controller.selectedCurrency.code, 'INR');
    expect(CurrencyFormatter.currency.code, 'INR');

    await controller.selectCurrency(
      AppCurrency.values.firstWhere((currency) => currency.code == 'EUR'),
    );
    expect(authRepository.currentProfile?.preferredCurrencyCode, 'EUR');
  });

  testWidgets('Profile shows Legal and opens Delete My Data', (tester) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = _controller(
      database: database,
      authRepository: SupabaseAuthRepository(client: null),
    );
    addTearDown(controller.dispose);
    await controller.bypassLoginForDevelopment();
    await tester.pumpWidget(
      MaterialApp(home: LedgerHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Legal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms & Disclaimer'), findsOneWidget);
    expect(find.text('Delete My Data'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Logout'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Logout'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Delete My Data'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Delete My Data'));
    await tester.pumpAndSettle();

    expect(find.text('Request Data Deletion'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Home profile button opens Profile and back returns Home', (
    tester,
  ) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = _controller(
      database: database,
      authRepository: SupabaseAuthRepository(client: null),
    );
    addTearDown(controller.dispose);
    await controller.bypassLoginForDevelopment();
    await tester.pumpWidget(
      MaterialApp(home: LedgerHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good day'), findsOneWidget);
    expect(find.text('Local User'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Good day'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-profile-button')), findsOneWidget);
  });

  testWidgets('Profile validates only the field being edited', (tester) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    final authRepository = SupabaseAuthRepository(client: null);
    final controller = _controller(
      database: database,
      authRepository: authRepository,
    );

    try {
      await controller.bypassLoginForDevelopment();
      await tester.pumpWidget(
        MaterialApp(home: LedgerHomeScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-profile-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-name')),
        'Updated User',
      );
      await tester.pump();

      expect(find.text('Enter a valid phone'), findsNothing);
    } finally {
      controller.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await authRepository.dispose();
      await database.close();
    }
  });
}

LedgerController _controller({
  required LedgerDatabase database,
  required AuthRepository authRepository,
}) {
  return LedgerController(
    authRepository: authRepository,
    ledgerRepository: DriftLedgerRepository(
      database: database,
      remoteDataSource: SupabaseLedgerRemoteDataSource(null),
    ),
    pdfStatementService: const PdfStatementService(),
  );
}

class _RestoringAuthRepository
    implements AuthRepository, PreferredCurrencyRepository {
  _RestoringAuthRepository(this._profile, {this.failRestore = false});

  UserProfile _profile;
  final bool failRestore;

  @override
  UserProfile? get currentProfile => _profile;

  @override
  Stream<UserProfile?> watchProfile() => const Stream.empty();

  @override
  Future<UserProfile?> restoreSession() async {
    if (failRestore) {
      throw StateError('Session restore failed.');
    }
    return _profile;
  }

  @override
  Future<UserProfile?> refreshProfile() async => _profile;

  @override
  Future<UserProfile> acceptPrivacyPolicy({required String version}) async {
    return _profile = _profile.copyWith(
      privacyPolicyAccepted: true,
      privacyPolicyAcceptedAt: DateTime.now(),
      privacyPolicyVersion: version,
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool privacyPolicyAccepted,
  }) async {}

  @override
  Future<void> resendEmailVerification(String email) async {}

  @override
  Future<String> requestPasswordReset(String identifier) async => identifier;

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
  }) async {
    return _profile = _profile.copyWith(name: name, phone: phone);
  }

  @override
  Future<UserProfile> updatePreferredCurrency(String currencyCode) async {
    return _profile = _profile.copyWith(preferredCurrencyCode: currencyCode);
  }

  @override
  Future<UserProfile> verifyEmailOtp({
    required String email,
    required String token,
  }) async => _profile;
}
