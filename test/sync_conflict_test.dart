import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_transaction.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';

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
    expect(row.pendingSync, isFalse);
    expect(remote.pushedServices, 1);
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

  test('new local entry is stored in monthly JSON log', () async {
    await _insertLocalService(
      database,
      name: 'Milkman',
      updatedAt: DateTime.utc(2026, 5),
      pendingSync: false,
    );

    await repository.saveEntry(
      ServiceEntry(
        id: 'entry-json-1',
        serviceId: serviceId,
        day: 4,
        monthKey: monthKey,
        status: ServiceEntryStatus.delivered,
        quantity: 1.5,
        unit: 'L',
        rateCents: 6000,
        amountCents: 9000,
        updatedAt: DateTime.utc(2026, 5, 4),
      ),
    );

    final legacyEntries = await database.select(database.entryRecords).get();
    final monthLog = await database
        .select(database.serviceMonthLogRecords)
        .getSingle();
    expect(legacyEntries, isEmpty);
    expect(monthLog.id, '$serviceId:$monthKey');
    expect(monthLog.entriesJson, contains('"4"'));
    expect(monthLog.entriesJson, contains('"quantity":1.5'));
    expect(monthLog.pendingSync, isTrue);
  });

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

  test('month hydration fetches once and then uses the Drift cache', () async {
    remote.services = [
      _remoteService(
        name: 'Remote Milkman',
        updatedAt: DateTime.utc(2026, 5, 2),
      ),
    ];

    await repository.hydrateMonth(userId: userId, monthKey: monthKey);
    await repository.hydrateMonth(userId: userId, monthKey: monthKey);

    expect(remote.serviceFetches, 1);
    expect(remote.entryFetches, 1);
    expect(remote.advanceFetches, 1);
    expect(remote.paymentFetches, 1);
    expect(remote.settlementFetches, 1);
    expect(
      await repository.isMonthCached(userId: userId, monthKey: monthKey),
      isTrue,
    );
  });

  test('forced month hydration refreshes an existing cache', () async {
    await repository.hydrateMonth(userId: userId, monthKey: monthKey);
    await repository.hydrateMonth(
      userId: userId,
      monthKey: monthKey,
      forceRefresh: true,
    );

    expect(remote.serviceFetches, 2);
    expect(remote.entryFetches, 2);
    expect(remote.advanceFetches, 2);
    expect(remote.paymentFetches, 2);
    expect(remote.settlementFetches, 2);
  });

  test(
    'logout sync pushes all user data then clears every local table',
    () async {
      await _insertCompleteLocalLedger(database);

      await repository.syncUserDataAndClearLocal(userId: userId);

      expect(remote.pushedServices, 1);
      expect(remote.pushedEntries, 1);
      expect(remote.pushedAdvances, 1);
      expect(remote.pushedPayments, 1);
      expect(remote.pushedSettlements, 1);
      expect(await database.select(database.profileRecords).get(), isEmpty);
      expect(await database.select(database.serviceRecords).get(), isEmpty);
      expect(await database.select(database.entryRecords).get(), isEmpty);
      expect(
        await database.select(database.advancePaymentRecords).get(),
        isEmpty,
      );
      expect(
        await database.select(database.paymentTransactionRecords).get(),
        isEmpty,
      );
      expect(
        await database.select(database.monthlySettlementRecords).get(),
        isEmpty,
      );
      expect(
        await database.select(database.syncMetadataRecords).get(),
        isEmpty,
      );
    },
  );

  test('logout sync failure keeps local data intact', () async {
    await _insertCompleteLocalLedger(database);
    remote.failOnEntryPush = true;

    await expectLater(
      repository.syncUserDataAndClearLocal(userId: userId),
      throwsStateError,
    );

    expect(await database.select(database.serviceRecords).get(), isNotEmpty);
    expect(await database.select(database.entryRecords).get(), isNotEmpty);
    expect(
      await database.select(database.advancePaymentRecords).get(),
      isNotEmpty,
    );
    expect(
      await database.select(database.paymentTransactionRecords).get(),
      isNotEmpty,
    );
    expect(
      await database.select(database.monthlySettlementRecords).get(),
      isNotEmpty,
    );
  });

  test('service is visible from the month containing its start date', () async {
    await database
        .into(database.serviceRecords)
        .insert(
          ServiceRecordsCompanion.insert(
            id: serviceId,
            userId: userId,
            monthKey: '2026-06',
            name: 'Milkman',
            description:
                'Provider: Ramesh • Start date: 25/05/2026 • Reminder: 30 minutes before',
            icon: 'milk',
            templateType: 'quantityBased',
            unit: 'L',
            rateCents: 6000,
            updatedAt: DateTime.utc(2026, 6, 1),
            pendingSync: const Value(false),
          ),
        );

    final overview = await repository.getOverview(
      userId: userId,
      monthKey: '2026-05',
    );

    expect(overview.services.map((service) => service.id), contains(serviceId));
    final corrected = await database
        .select(database.serviceRecords)
        .getSingle();
    expect(corrected.monthKey, '2026-05');
    expect(remote.pushedServices, greaterThanOrEqualTo(1));
  });

  test('service start month excludes stale earlier carry forward', () async {
    final now = DateTime.utc(2026, 5, 25);
    await database
        .into(database.serviceRecords)
        .insert(
          ServiceRecordsCompanion.insert(
            id: serviceId,
            userId: userId,
            monthKey: monthKey,
            name: 'Milkman',
            description: 'Provider: Test • Start date: 25/05/2026',
            icon: 'milk',
            templateType: 'quantity',
            unit: 'L',
            rateCents: 70000,
            updatedAt: now,
          ),
        );
    await database
        .into(database.entryRecords)
        .insert(
          EntryRecordsCompanion.insert(
            id: 'entry-may-25',
            serviceId: serviceId,
            monthKey: monthKey,
            day: 25,
            status: 'delivered',
            quantity: const Value(1),
            unit: const Value('L'),
            rateCents: const Value(70000),
            amountCents: const Value(70000),
            updatedAt: now,
          ),
        );
    await database
        .into(database.monthlySettlementRecords)
        .insert(
          MonthlySettlementRecordsCompanion.insert(
            id: '${userId}_${serviceId}_2026-04',
            userId: userId,
            serviceId: serviceId,
            monthKey: '2026-04',
            grossAmountCents: const Value(70000),
            payableAmountCents: const Value(70000),
            remainingAmountCents: const Value(70000),
            carryForwardToNextMonthCents: const Value(70000),
            status: 'pending',
            generatedAt: now,
            updatedAt: now,
          ),
        );

    final bill = await repository.getMonthlyBill(
      serviceId: serviceId,
      monthKey: monthKey,
    );

    expect(bill.grossAmountCents, 70000);
    expect(bill.settlement?.previousCarryForwardCents, 0);
    expect(bill.payableAmountCents, 70000);
  });

  test('saved payment amount and allocation are pushed to Supabase', () async {
    final now = DateTime.utc(2026, 5, 25);
    await _insertLocalService(
      database,
      name: 'Milkman',
      updatedAt: now,
      pendingSync: false,
    );
    await database
        .into(database.entryRecords)
        .insert(
          EntryRecordsCompanion.insert(
            id: 'entry-payment-sync',
            serviceId: serviceId,
            monthKey: monthKey,
            day: 25,
            status: 'delivered',
            quantity: const Value(1),
            unit: const Value('L'),
            rateCents: const Value(70000),
            amountCents: const Value(70000),
            updatedAt: now,
          ),
        );

    await repository.savePayment(
      PaymentTransaction(
        id: 'payment-sync',
        userId: userId,
        serviceId: serviceId,
        monthKey: monthKey,
        amountCents: 30000,
        paymentDate: now,
        mode: PaymentMode.upi,
        updatedAt: now,
      ),
    );
    await repository.syncPending();

    expect(remote.pushedPayments, 1);
    expect(remote.lastPushedPayment?.amountCents, 30000);
    expect(remote.lastPushedPayment?.currentMonthAmountCents, 30000);
    expect(remote.lastPushedPayment?.previousBalanceAmountCents, 0);
    expect(remote.lastPushedPayment?.advanceAmountCents, 0);
  });

  test(
    'future payment settles previous month and appears in previous month history',
    () async {
      final mayDate = DateTime.utc(2026, 5, 31);
      final juneDate = DateTime.utc(2026, 6, 8);
      await _insertLocalService(
        database,
        name: 'Milkman',
        updatedAt: mayDate,
        pendingSync: false,
      );
      await database
          .into(database.entryRecords)
          .insert(
            EntryRecordsCompanion.insert(
              id: 'entry-may-due',
              serviceId: serviceId,
              monthKey: monthKey,
              day: 31,
              status: 'delivered',
              quantity: const Value(1),
              unit: const Value('L'),
              rateCents: const Value(98000),
              amountCents: const Value(98000),
              updatedAt: mayDate,
            ),
          );

      final mayBeforePayment = await repository.getMonthlyBill(
        serviceId: serviceId,
        monthKey: monthKey,
      );
      expect(mayBeforePayment.payableAmountCents, 98000);

      await repository.savePayment(
        PaymentTransaction(
          id: 'payment-june-settles-may',
          userId: userId,
          serviceId: serviceId,
          monthKey: '2026-06',
          amountCents: 100000,
          paymentDate: juneDate,
          mode: PaymentMode.upi,
          updatedAt: juneDate,
        ),
      );

      final mayAfterPayment = await repository.getMonthlyBill(
        serviceId: serviceId,
        monthKey: monthKey,
      );
      final mayPayments = await repository.getPayments(
        serviceId: serviceId,
        monthKey: monthKey,
      );

      expect(mayAfterPayment.payableAmountCents, 0);
      expect(mayAfterPayment.settlement?.paidAmountCents, 98000);
      expect(mayPayments, hasLength(1));
      expect(mayPayments.single.paymentDate.year, juneDate.year);
      expect(mayPayments.single.paymentDate.month, juneDate.month);
      expect(mayPayments.single.paymentDate.day, juneDate.day);
      expect(mayPayments.single.amountCents, 98000);

      final juneRows = await database
          .select(database.paymentTransactionRecords)
          .get();
      final junePayment = juneRows.singleWhere(
        (row) => row.id == 'payment-june-settles-may',
      );
      expect(junePayment.previousBalanceAmountCents, 98000);
      expect(junePayment.advanceAmountCents, 2000);
    },
  );

  test(
    'deleted payment is removed locally and deleted from Supabase',
    () async {
      final now = DateTime.utc(2026, 5, 25);
      await _insertLocalService(
        database,
        name: 'Milkman',
        updatedAt: now,
        pendingSync: false,
      );
      final payment = PaymentTransaction(
        id: 'payment-delete-sync',
        userId: userId,
        serviceId: serviceId,
        monthKey: monthKey,
        amountCents: 30000,
        paymentDate: now,
        mode: PaymentMode.upi,
        updatedAt: now,
      );

      await repository.savePayment(payment);
      await repository.syncPending();

      await repository.deletePayment(payment);

      final rows = await database
          .select(database.paymentTransactionRecords)
          .get();
      expect(rows.where((row) => row.id == 'payment-delete-sync'), isEmpty);
      expect(remote.deletedPaymentIds, ['payment-delete-sync']);
    },
  );

  test(
    'concurrent entries for one service settle without lost updates',
    () async {
      final now = DateTime.utc(2026, 5, 20);
      await _insertLocalService(
        database,
        name: 'Milkman',
        updatedAt: now,
        pendingSync: false,
      );

      await Future.wait([
        repository.saveEntry(
          ServiceEntry(
            id: 'entry-concurrent-1',
            serviceId: serviceId,
            day: 1,
            monthKey: monthKey,
            status: ServiceEntryStatus.delivered,
            quantity: 1,
            unit: 'L',
            rateCents: 6000,
            amountCents: 6000,
            updatedAt: now,
          ),
        ),
        repository.saveEntry(
          ServiceEntry(
            id: 'entry-concurrent-2',
            serviceId: serviceId,
            day: 2,
            monthKey: monthKey,
            status: ServiceEntryStatus.delivered,
            quantity: 1,
            unit: 'L',
            rateCents: 6000,
            amountCents: 6000,
            updatedAt: now,
          ),
        ),
      ]);

      final bill = await repository.getMonthlyBill(
        serviceId: serviceId,
        monthKey: monthKey,
      );

      expect(bill.grossAmountCents, 12000);
      expect(bill.service.entries, hasLength(2));
    },
  );

  test('overview stream reacts to entry changes', () async {
    final now = DateTime.utc(2026, 5, 20);
    await _insertLocalService(
      database,
      name: 'Milkman',
      updatedAt: now,
      pendingSync: false,
    );
    final values = <dynamic>[];
    final firstOverview = Completer<void>();
    final secondOverview = Completer<void>();
    final subscription = repository
        .watchOverview(userId: userId, monthKey: monthKey)
        .listen((overview) {
          values.add(overview);
          if (values.length == 1) {
            firstOverview.complete();
          } else if (values.length == 2) {
            secondOverview.complete();
          }
        });
    addTearDown(subscription.cancel);

    await firstOverview.future;
    await database
        .into(database.entryRecords)
        .insert(
          EntryRecordsCompanion.insert(
            id: 'reactive-entry',
            serviceId: serviceId,
            monthKey: monthKey,
            day: 1,
            status: 'delivered',
            quantity: const Value(1),
            unit: const Value('L'),
            rateCents: const Value(6000),
            amountCents: const Value(6000),
            updatedAt: now,
          ),
        );

    await secondOverview.future;
    expect(values.first.services.single.entries, isEmpty);
    expect(values.last.services.single.entries, hasLength(1));
  });
}

Future<void> _insertCompleteLocalLedger(LedgerDatabase database) async {
  final now = DateTime.utc(2026, 5, 20);
  await database
      .into(database.profileRecords)
      .insert(
        ProfileRecordsCompanion.insert(
          id: userId,
          name: 'Test User',
          email: 'test@example.com',
          phone: '+919999999999',
          emailVerified: const Value(true),
          updatedAt: now,
          pendingSync: const Value(true),
        ),
      );
  await _insertLocalService(
    database,
    name: 'Milkman',
    updatedAt: now,
    pendingSync: true,
  );
  await database
      .into(database.entryRecords)
      .insert(
        EntryRecordsCompanion.insert(
          id: 'entry-1',
          serviceId: serviceId,
          monthKey: monthKey,
          day: 20,
          status: 'delivered',
          quantity: const Value(1),
          unit: const Value('L'),
          rateCents: const Value(6000),
          amountCents: const Value(6000),
          updatedAt: now,
          pendingSync: const Value(true),
        ),
      );
  await database
      .into(database.advancePaymentRecords)
      .insert(
        AdvancePaymentRecordsCompanion.insert(
          id: 'advance-1',
          serviceId: serviceId,
          monthKey: monthKey,
          amountCents: 5000,
          paidOn: now,
          updatedAt: now,
          pendingSync: const Value(true),
        ),
      );
  await database
      .into(database.paymentTransactionRecords)
      .insert(
        PaymentTransactionRecordsCompanion.insert(
          id: 'payment-1',
          userId: userId,
          serviceId: serviceId,
          monthKey: monthKey,
          amountCents: 4000,
          paymentDate: now,
          paymentMode: 'cash',
          currentMonthAmountCents: const Value(4000),
          createdAt: now,
          updatedAt: now,
          pendingSync: const Value(true),
        ),
      );
  await database
      .into(database.monthlySettlementRecords)
      .insert(
        MonthlySettlementRecordsCompanion.insert(
          id: '${userId}_${serviceId}_$monthKey',
          userId: userId,
          serviceId: serviceId,
          monthKey: monthKey,
          grossAmountCents: const Value(6000),
          payableAmountCents: const Value(6000),
          paidAmountCents: const Value(4000),
          remainingAmountCents: const Value(2000),
          carryForwardToNextMonthCents: const Value(2000),
          status: 'partiallyPaid',
          generatedAt: now,
          updatedAt: now,
          pendingSync: const Value(true),
        ),
      );
  await database
      .into(database.syncMetadataRecords)
      .insert(
        SyncMetadataRecordsCompanion.insert(
          id: 'preference:currency_code',
          entityType: 'USD',
          lastSyncedAt: Value(now),
        ),
      );
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
  List<Map<String, dynamic>> monthLogs = const [];
  List<Map<String, dynamic>> entries = const [];
  List<Map<String, dynamic>> advances = const [];
  List<Map<String, dynamic>> payments = const [];
  List<Map<String, dynamic>> settlements = const [];
  int? schemaVersion = 5;
  bool failOnEntryPush = false;
  int pushedServices = 0;
  int pushedMonthLogs = 0;
  int pushedEntries = 0;
  int pushedAdvances = 0;
  int pushedPayments = 0;
  int pushedSettlements = 0;
  int serviceFetches = 0;
  int monthLogFetches = 0;
  int entryFetches = 0;
  int advanceFetches = 0;
  int paymentFetches = 0;
  int settlementFetches = 0;
  PaymentTransactionRecord? lastPushedPayment;
  final deletedPaymentIds = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<int?> fetchSchemaVersion() async => schemaVersion;

  @override
  Future<List<Map<String, dynamic>>> fetchServices({
    required String userId,
    required String monthKey,
  }) async {
    serviceFetches++;
    return services;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEntries({
    required String monthKey,
  }) async {
    entryFetches++;
    return entries;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthLogs({
    required String monthKey,
  }) async {
    monthLogFetches++;
    return monthLogs;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdvances({
    required String monthKey,
  }) async {
    advanceFetches++;
    return advances;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayments({
    required String monthKey,
  }) async {
    paymentFetches++;
    return payments;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSettlements({
    required String monthKey,
  }) async {
    settlementFetches++;
    return settlements;
  }

  @override
  Future<void> pushAdvance(AdvancePaymentRecord row) async {
    pushedAdvances++;
  }

  @override
  Future<void> pushEntry(EntryRecord row) async {
    if (failOnEntryPush) {
      throw StateError('Remote entry push failed.');
    }
    pushedEntries++;
  }

  @override
  Future<void> pushMonthLog(ServiceMonthLogRecord row) async {
    pushedMonthLogs++;
  }

  @override
  Future<void> pushPayment(PaymentTransactionRecord row) async {
    pushedPayments++;
    lastPushedPayment = row;
  }

  @override
  Future<void> deletePayment(String id) async {
    deletedPaymentIds.add(id);
  }

  @override
  Future<void> pushSettlement(MonthlySettlementRecord row) async {
    pushedSettlements++;
  }

  @override
  Future<void> pushService(ServiceRecord row) async {
    pushedServices++;
  }
}
