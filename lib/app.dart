import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/ledger/data/database/ledger_database.dart';
import 'features/ledger/data/repositories/drift_ledger_repository.dart';
import 'features/ledger/data/repositories/supabase_auth_repository.dart';
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

  @override
  void initState() {
    super.initState();
    final appDatabase = widget.database ?? LedgerDatabase.defaults();
    final authRepository = SupabaseAuthRepository(
      client: widget.supabaseClient,
    );
    final ledgerRepository = DriftLedgerRepository(
      database: appDatabase,
      remoteDataSource: SupabaseLedgerRemoteDataSource(widget.supabaseClient),
    );
    _controller = LedgerController(
      authRepository: authRepository,
      ledgerRepository: ledgerRepository,
      pdfStatementService: const PdfStatementService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Daily Service Ledger',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _controller.selectedThemeMode,
        home: LedgerHomeScreen(controller: _controller),
      ),
    );
  }
}
