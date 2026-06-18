import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/mappers/month_log_entry_codec.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/advance_payment.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/payment_transaction.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/entry_operations_controller.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/payment_operations_controller.dart';

void main() {
  late LedgerDatabase database;
  late DriftLedgerRepository repository;
  late HouseholdService service;

  setUp(() async {
    database = LedgerDatabase(NativeDatabase.memory());
    repository = DriftLedgerRepository(
      database: database,
      remoteDataSource: SupabaseLedgerRemoteDataSource(null),
    );
    service = HouseholdService(
      id: 'service',
      userId: 'local-user',
      name: 'Milkman',
      description: 'Start date: 10/06/2026',
      icon: 'milk',
      templateType: ServiceTemplateType.quantity,
      monthKey: '2026-06',
      unit: 'L',
      defaultQuantity: 1,
      rateCents: 6000,
      monthlyAmountCents: 0,
      entries: const [],
      updatedAt: DateTime(2026, 6, 10),
    );
    await database
        .into(database.serviceRecords)
        .insert(
          ServiceRecordsCompanion.insert(
            id: service.id,
            userId: service.userId,
            monthKey: service.monthKey,
            name: service.name,
            description: service.description,
            icon: service.icon,
            templateType: service.templateType.name,
            unit: service.unit,
            defaultQuantity: Value(service.defaultQuantity),
            rateCents: service.rateCents,
            monthlyAmountCents: Value(service.monthlyAmountCents),
            updatedAt: service.updatedAt,
          ),
        );
  });

  tearDown(() => database.close());

  test(
    'entry operations calculate decimal quantity and persist locally',
    () async {
      final operations = EntryOperationsController(repository);
      ServiceEntry? optimisticEntry;

      final entry = await operations.save(
        service: service,
        monthKey: '2026-06',
        day: 10,
        status: ServiceEntryStatus.delivered,
        quantity: 1.5,
        unit: 'L',
        rateCents: 6000,
        note: '',
        onPrepared: (value) => optimisticEntry = value,
      );

      expect(optimisticEntry?.id, entry.id);
      expect(entry.amountCents, 9000);
      final rows = await database.select(database.serviceMonthLogRecords).get();
      final persistedEntries = MonthLogEntryCodec.decode(
        entriesJson: rows.single.entriesJson,
        serviceId: service.id,
        monthKey: '2026-06',
      );
      expect(persistedEntries.single.quantity, 1.5);
      expect(persistedEntries.single.amountCents, 9000);
    },
  );

  test('entry operations reject dates before service start', () async {
    final operations = EntryOperationsController(repository);

    await expectLater(
      operations.saveDefault(service: service, monthKey: '2026-06', day: 9),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Service started from 10 Jun 2026'),
        ),
      ),
    );
  });

  test('entry operations reject future delivery dates', () async {
    final operations = EntryOperationsController(repository);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final futureMonthKey =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}';

    await expectLater(
      operations.saveDefault(
        service: service,
        monthKey: futureMonthKey,
        day: tomorrow.day,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Entries can only be logged on or after the service date.',
        ),
      ),
    );
  });

  test(
    'payment operations construct and persist payment transactions',
    () async {
      final operations = PaymentOperationsController(repository);

      await operations.savePayment(
        userId: 'local-user',
        service: service,
        monthKey: '2026-06',
        amountCents: 12000,
        paymentDate: DateTime(2026, 6, 20),
        mode: PaymentMode.upi,
        note: 'June payment',
      );

      final history = await operations.paymentHistory(service.id);
      expect(history.single.amountCents, 12000);
      expect(history.single.mode, PaymentMode.upi);
      expect(history.single.pendingSync, isTrue);
    },
  );

  test('advance operations support create, update, and delete', () async {
    final operations = PaymentOperationsController(repository);
    final advance = AdvancePayment(
      id: 'advance-1',
      serviceId: service.id,
      monthKey: '2026-06',
      amountCents: 50000,
      paidOn: DateTime(2026, 6, 12),
      note: 'Cash',
    );

    await repository.saveAdvance(advance);
    await operations.updateAdvance(
      advance: advance,
      amountCents: 75000,
      paidOn: DateTime(2026, 6, 13),
      note: 'UPI',
    );

    var history = await repository.getAdvanceHistory(serviceId: service.id);
    expect(history.single.amountCents, 75000);
    expect(history.single.note, 'UPI');

    await operations.deleteAdvance(history.single);

    history = await repository.getAdvanceHistory(serviceId: service.id);
    expect(history, isEmpty);
    final rows = await database.select(database.advancePaymentRecords).get();
    expect(rows.single.isDeleted, isTrue);
    expect(rows.single.pendingSync, isTrue);
  });
}
