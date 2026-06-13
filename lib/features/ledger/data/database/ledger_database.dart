import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'ledger_database.g.dart';

class ProfileRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  BoolColumn get emailVerified =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ServiceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get monthKey => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get icon => text()();
  TextColumn get templateType => text()();
  TextColumn get unit => text()();
  RealColumn get defaultQuantity => real().withDefault(const Constant(1))();
  IntColumn get rateCents => integer()();
  IntColumn get monthlyAmountCents =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ServiceMonthLogRecords extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get monthKey => text()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  TextColumn get entriesJson => text().withDefault(
    const Constant('{"schemaVersion":1,"overrides":{}}'),
  )();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AdvancePaymentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get monthKey => text()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get paidOn => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PaymentTransactionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get serviceId => text()();
  TextColumn get monthKey => text()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMode => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get currentMonthAmountCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get previousBalanceAmountCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get advanceAmountCents =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MonthlySettlementRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get serviceId => text()();
  TextColumn get monthKey => text()();
  IntColumn get grossAmountCents => integer().withDefault(const Constant(0))();
  IntColumn get advanceUsedCents => integer().withDefault(const Constant(0))();
  IntColumn get previousCarryForwardCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get previousAdvanceCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get payableAmountCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get paidAmountCents => integer().withDefault(const Constant(0))();
  IntColumn get remainingAmountCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get carryForwardToNextMonthCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get advanceToNextMonthCents =>
      integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncMetadataRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ProfileRecords,
    ServiceRecords,
    ServiceMonthLogRecords,
    AdvancePaymentRecords,
    PaymentTransactionRecords,
    MonthlySettlementRecords,
    SyncMetadataRecords,
  ],
)
class LedgerDatabase extends _$LedgerDatabase {
  LedgerDatabase(super.executor);

  LedgerDatabase.defaults() : super(driftDatabase(name: 'payqure_ledger'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.dropColumn(profileRecords, 'phone_verified');
      }
      if (from < 3) {
        await m.createTable(paymentTransactionRecords);
        await m.createTable(monthlySettlementRecords);
      }
      if (from < 4) {
        await m.addColumn(
          paymentTransactionRecords,
          paymentTransactionRecords.currentMonthAmountCents,
        );
        await m.addColumn(
          paymentTransactionRecords,
          paymentTransactionRecords.previousBalanceAmountCents,
        );
        await m.addColumn(
          paymentTransactionRecords,
          paymentTransactionRecords.advanceAmountCents,
        );
      }
      if (from < 5) {
        await m.createTable(serviceMonthLogRecords);
      }
      if (from < 6) {
        await m.deleteTable('entry_records');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
