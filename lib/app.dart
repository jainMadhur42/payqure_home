import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/ledger/data/database/ledger_database.dart';
import 'features/ledger/data/repositories/drift_ledger_repository.dart';
import 'features/ledger/data/repositories/supabase_auth_repository.dart';
import 'features/ledger/data/services/local_notification_service.dart';
import 'features/ledger/data/services/pdf_statement_service.dart';
import 'features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'features/ledger/presentation/controllers/ledger_controller.dart';
import 'features/ledger/presentation/screens/ledger_home_screen.dart';

class PayqureHomeApp extends StatefulWidget {
  const PayqureHomeApp({this.supabaseClient, this.database, super.key});

  final SupabaseClient? supabaseClient;
  final LedgerDatabase? database;

  @override
  State<PayqureHomeApp> createState() => _PayqureHomeAppState();
}

class _PayqureHomeAppState extends State<PayqureHomeApp> {
  late final LedgerController _controller;
  late final LedgerDatabase _database;
  late final SupabaseAuthRepository _authRepository;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? LedgerDatabase.defaults();
    _authRepository = SupabaseAuthRepository(client: widget.supabaseClient);
    final ledgerRepository = DriftLedgerRepository(
      database: _database,
      remoteDataSource: SupabaseLedgerRemoteDataSource(widget.supabaseClient),
    );
    _controller = LedgerController(
      authRepository: _authRepository,
      ledgerRepository: ledgerRepository,
      pdfStatementService: const PdfStatementService(),
      reminderScheduler: LocalNotificationService(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_authRepository.dispose());
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _controller.themeModeListenable,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Daily Service Ledger',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: LedgerHomeScreen(controller: _controller),
      ),
    );
  }
}
