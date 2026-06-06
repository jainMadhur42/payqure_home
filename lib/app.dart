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

class PayqureHomeApp extends StatelessWidget {
  const PayqureHomeApp({this.supabaseClient, this.database, super.key});

  final SupabaseClient? supabaseClient;
  final LedgerDatabase? database;

  @override
  Widget build(BuildContext context) {
    final appDatabase = database ?? LedgerDatabase.defaults();
    final authRepository = SupabaseAuthRepository(client: supabaseClient);
    final ledgerRepository = DriftLedgerRepository(
      database: appDatabase,
      remoteDataSource: SupabaseLedgerRemoteDataSource(supabaseClient),
    );
    final controller = LedgerController(
      authRepository: authRepository,
      ledgerRepository: ledgerRepository,
      pdfStatementService: const PdfStatementService(),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Service Ledger',
      theme: AppTheme.light,
      home: LedgerHomeScreen(controller: controller),
    );
  }
}
