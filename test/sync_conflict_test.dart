import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';

const userId = 'user-1';
const monthKey = '2026-05';
const serviceId = 'service-1';

void main() {
  late LedgerDatabase database;
  late _FakeRemoteDataSource remote;
  late DriftLedgerRepository repository;

  setUp(() {
    database = LedgerDatabase(NativeDatabase.memory());
    remote = _FakeRemoteDataSource();
    repository = DriftLedgerRepository(
      database: database,
      remoteDataSource: remote,
    );
  });

  tearDown(() => database.close());

  test('newer pending local service wins over older remote row', () async {
    final localUpdatedAt = DateTime.utc(2026, 5, 2);
    final remoteUpdatedAt = DateTime.utc(2026, 5, 1);
    await _insertLocalService(
      database,
      name: 'Local Milkman',
      updatedAt: localUpdatedAt,
      pendingSync: true,
    );
    remote.services = [
      _remoteService(name: 'Remote Milkman', updatedAt: remoteUpdatedAt),
    ];

    await repository.syncRemoteChanges(userId: userId, monthKey: monthKey);

    final row = await database.select(database.serviceRecords).getSingle();
    expect(row.name, 'Local Milkman');
    expect(row.pendingSync, isTrue);
  });

  test('newer remote service replaces older local row', () async {
    final localUpdatedAt = DateTime.utc(2026, 5, 1);
    final remoteUpdatedAt = DateTime.utc(2026, 5, 2);
    await _insertLocalService(
      database,
      name: 'Local Milkman',
      updatedAt: localUpdatedAt,
      pendingSync: false,
    );
    remote.services = [
      _remoteService(name: 'Remote Milkman', updatedAt: remoteUpdatedAt),
    ];

    await repository.syncRemoteChanges(userId: userId, monthKey: monthKey);

    final row = await database.select(database.serviceRecords).getSingle();
    expect(row.name, 'Remote Milkman');
    expect(row.pendingSync, isFalse);
  });

  test(
    'newer remote entry and advance are merged into local database',
    () async {
      final remoteUpdatedAt = DateTime.utc(2026, 5, 3);
      await _insertLocalService(
        database,
        name: 'Milkman',
        updatedAt: DateTime.utc(2026, 5, 1),
        pendingSync: false,
      );
      remote.entries = [
        {
          'id': 'entry-1',
          'service_id': serviceId,
          'month_key': monthKey,
          'day': 3,
          'status': 'delivered',
          'quantity': 2.0,
          'unit': 'L',
          'rate_cents': 6000,
          'amount_cents': 12000,
          'note': 'Remote delivery',
          'updated_at': remoteUpdatedAt.toIso8601String(),
          'is_deleted': false,
        },
      ];
      remote.advances = [
        {
          'id': 'advance-1',
          'service_id': serviceId,
          'month_key': monthKey,
          'amount_cents': 50000,
          'paid_on': remoteUpdatedAt.toIso8601String(),
          'note': 'Remote advance',
          'updated_at': remoteUpdatedAt.toIso8601String(),
          'is_deleted': false,
        },
      ];

      await repository.syncRemoteChanges(userId: userId, monthKey: monthKey);

      final entry = await database.select(database.entryRecords).getSingle();
      final advance = await database
          .select(database.advancePaymentRecords)
          .getSingle();
      expect(entry.note, 'Remote delivery');
      expect(entry.amountCents, 12000);
      expect(advance.note, 'Remote advance');
      expect(advance.amountCents, 50000);
    },
  );

  test('remote sync fails clearly when backend schema is missing', () {
    remote.schemaVersion = null;

    expect(
      () => repository.syncRemoteChanges(userId: userId, monthKey: monthKey),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('latest migration'),
        ),
      ),
    );
  });
}

Future<void> _insertLocalService(
  LedgerDatabase database, {
  required String name,
  required DateTime updatedAt,
  required bool pendingSync,
}) {
  return database
      .into(database.serviceRecords)
      .insert(
        ServiceRecordsCompanion.insert(
          id: serviceId,
          userId: userId,
          monthKey: monthKey,
          name: name,
          description: '30 L / Month',
          icon: 'milk',
          templateType: 'quantity',
          unit: 'L',
          rateCents: 6000,
          updatedAt: updatedAt,
          pendingSync: Value(pendingSync),
        ),
      );
}

Map<String, dynamic> _remoteService({
  required String name,
  required DateTime updatedAt,
}) {
  return {
    'id': serviceId,
    'user_id': userId,
    'month_key': monthKey,
    'name': name,
    'description': '30 L / Month',
    'icon': 'milk',
    'template_type': 'quantity',
    'unit': 'L',
    'default_quantity': 1.0,
    'rate_cents': 6000,
    'monthly_amount_cents': 180000,
    'updated_at': updatedAt.toIso8601String(),
    'is_deleted': false,
  };
}

class _FakeRemoteDataSource implements LedgerRemoteDataSource {
  List<Map<String, dynamic>> services = const [];
  List<Map<String, dynamic>> entries = const [];
  List<Map<String, dynamic>> advances = const [];
  List<Map<String, dynamic>> payments = const [];
  List<Map<String, dynamic>> settlements = const [];
  int? schemaVersion = 2;

  @override
  bool get isConfigured => true;

  @override
  Future<int?> fetchSchemaVersion() async => schemaVersion;

  @override
  Future<List<Map<String, dynamic>>> fetchServices({
    required String userId,
    required String monthKey,
  }) async {
    return services;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEntries({
    required String monthKey,
  }) async {
    return entries;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdvances({
    required String monthKey,
  }) async {
    return advances;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayments({
    required String monthKey,
  }) async {
    return payments;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSettlements({
    required String monthKey,
  }) async {
    return settlements;
  }

  @override
  Future<void> pushAdvance(AdvancePaymentRecord row) async {}

  @override
  Future<void> pushEntry(EntryRecord row) async {}

  @override
  Future<void> pushPayment(PaymentTransactionRecord row) async {}

  @override
  Future<void> pushSettlement(MonthlySettlementRecord row) async {}

  @override
  Future<void> pushService(ServiceRecord row) async {}
}
