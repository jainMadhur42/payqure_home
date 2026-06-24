import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/analytics/app_analytics.dart';
import 'core/app_info/app_version_provider.dart';
import 'core/app_info/app_compatibility_repository.dart';
import 'core/theme/accent_color.dart';
import 'core/theme/app_theme.dart';
import 'common/widgets/keyboard_done_accessory.dart';
import 'features/ledger/data/database/ledger_database.dart';
import 'features/ledger/data/repositories/drift_ledger_repository.dart';
import 'features/ledger/data/repositories/supabase_auth_repository.dart';
import 'features/ledger/data/services/local_notification_service.dart';
import 'features/ledger/data/services/pdf_statement_service.dart';
import 'features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'features/ledger/presentation/controllers/ledger_controller.dart';
import 'features/ledger/presentation/screens/ledger_home_screen.dart';

class PayqureHomeApp extends StatefulWidget {
  const PayqureHomeApp({
    this.supabaseClient,
    this.database,
    this.analytics,
    super.key,
  });

  final SupabaseClient? supabaseClient;
  final LedgerDatabase? database;
  final AppAnalytics? analytics;

  @override
  State<PayqureHomeApp> createState() => _PayqureHomeAppState();
}

class _PayqureHomeAppState extends State<PayqureHomeApp>
    with WidgetsBindingObserver {
  late final LedgerController _controller;
  late final LedgerDatabase _database;
  late final SupabaseAuthRepository _authRepository;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? LedgerDatabase.defaults();
    _authRepository = SupabaseAuthRepository(client: widget.supabaseClient);
    final analytics = widget.analytics ?? AppAnalytics.disabled();
    final ledgerRepository = DriftLedgerRepository(
      database: _database,
      remoteDataSource: SupabaseLedgerRemoteDataSource(widget.supabaseClient),
      analytics: analytics,
    );
    _controller = LedgerController(
      authRepository: _authRepository,
      ledgerRepository: ledgerRepository,
      pdfStatementService: const PdfStatementService(),
      reminderScheduler: LocalNotificationService(),
      analytics: analytics,
      appVersionProvider: const PackageInfoAppVersionProvider(),
      appCompatibilityRepository: SupabaseAppCompatibilityRepository(
        widget.supabaseClient,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    unawaited(_authRepository.dispose());
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.restoreServiceReminders(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _controller.themeModeListenable,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<AppAccentColor>(
          valueListenable: _controller.accentColorListenable,
          builder: (context, accent, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Daily Service Ledger',
            theme: AppTheme.light(accent.color),
            darkTheme: AppTheme.dark(accent.color),
            themeMode: themeMode,
            builder: (context, child) =>
                KeyboardDoneAccessory(child: child ?? const SizedBox.shrink()),
            home: LedgerHomeScreen(controller: _controller),
          ),
        );
      },
    );
  }
}
