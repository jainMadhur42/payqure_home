import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payqure_home/core/app_info/app_compatibility.dart';
import 'package:payqure_home/core/app_info/app_compatibility_repository.dart';
import 'package:payqure_home/core/app_info/app_version_provider.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/app_route.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/ledger/presentation/screens/app_update_required_screen.dart';

import 'support/app_version.dart';

const _minimumSupportedAppVersion = '1.2.0';
// Single source of truth: the latest app version comes from pubspec.yaml.
final _latestAppVersion = readPubspecAppVersion();
const _supportedOlderAppVersion = '1.3.0';
const _unsupportedAppVersion = '1.1.0';
final _compatibilityFixture = AppCompatibilityConfig(
  currentSchemaVersion: 6,
  minimumSupportedSchemaVersion: 3,
  minimumAppVersion: _minimumSupportedAppVersion,
  latestAppVersion: _latestAppVersion,
);

void main() {
  group('AppCompatibilityEvaluator', () {
    test('accepts the latest app and schema', () {
      final decision = _evaluate(
        appVersion: _latestAppVersion,
        schemaVersion: 6,
      );

      expect(decision.status, AppCompatibilityStatus.compatible);
      expect(decision.blocksApp, isFalse);
    });

    test('keeps a supported older app usable', () {
      final decision = _evaluate(
        appVersion: _supportedOlderAppVersion,
        schemaVersion: 5,
      );

      expect(decision.status, AppCompatibilityStatus.updateAvailable);
      expect(decision.blocksApp, isFalse);
    });

    test('requires an update below the minimum app version', () {
      final decision = _evaluate(appVersion: '1.1.9', schemaVersion: 6);

      expect(decision.status, AppCompatibilityStatus.appUpdateRequired);
      expect(decision.blocksApp, isTrue);
    });

    test('requires an update below the minimum client schema', () {
      final decision = _evaluate(
        appVersion: _latestAppVersion,
        schemaVersion: 2,
      );

      expect(decision.status, AppCompatibilityStatus.appUpdateRequired);
      expect(decision.blocksApp, isTrue);
    });

    test('waits for backend upgrade when client schema is newer', () {
      final decision = _evaluate(
        appVersion: _latestAppVersion,
        schemaVersion: 7,
      );

      expect(decision.status, AppCompatibilityStatus.backendUpgradeRequired);
      expect(decision.blocksApp, isTrue);
    });

    test('serializes the database compatibility shape', () {
      final restored = AppCompatibilityConfig.fromJson(
        _compatibilityFixture.toJson(),
      );

      expect(restored.currentSchemaVersion, 6);
      expect(restored.minimumSupportedSchemaVersion, 3);
      expect(restored.minimumAppVersion, _minimumSupportedAppVersion);
      expect(restored.latestAppVersion, _latestAppVersion);
    });
  });

  test('startup blocks an app below the minimum version', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = LedgerController(
      authRepository: SupabaseAuthRepository(client: null),
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
      appVersionProvider: const _TestAppVersionProvider(_unsupportedAppVersion),
      appCompatibilityRepository: _TestCompatibilityRepository(
        _compatibilityFixture,
      ),
    );
    addTearDown(controller.dispose);

    await controller.completeSplash();

    expect(controller.route, LedgerRoute.appUpdateRequired);
    expect(controller.appCompatibilityDecision?.blocksApp, isTrue);
  });

  testWidgets('forced update screen explains the required version', (
    tester,
  ) async {
    final decision = _evaluate(
      appVersion: _unsupportedAppVersion,
      schemaVersion: 6,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateRequiredScreen(decision: decision, onRetry: () async {}),
      ),
    );

    expect(find.text('Update Payqure Home'), findsOneWidget);
    expect(find.textContaining(_latestAppVersion), findsOneWidget);
    expect(find.text('Update App'), findsOneWidget);
    expect(find.text('Check Again'), findsOneWidget);
  });
}

AppCompatibilityDecision _evaluate({
  required String appVersion,
  required int schemaVersion,
}) {
  return AppCompatibilityEvaluator.evaluate(
    config: _compatibilityFixture,
    installedAppVersion: appVersion,
    clientSchemaVersion: schemaVersion,
  );
}

class _TestAppVersionProvider implements AppVersionProvider {
  const _TestAppVersionProvider(this.version);

  final String version;

  @override
  Future<AppVersionInfo> load() async {
    return AppVersionInfo(version: version, buildNumber: '1');
  }
}

class _TestCompatibilityRepository implements AppCompatibilityRepository {
  const _TestCompatibilityRepository(this.config);

  final AppCompatibilityConfig config;

  @override
  Future<AppCompatibilityConfig?> fetch() async => config;
}
