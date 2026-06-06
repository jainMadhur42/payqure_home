import 'package:drift/drift.dart';

import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/advance_payment.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_overview.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/bill_calculator.dart';
import '../../domain/services/settlement_calculator.dart';
import '../database/ledger_database.dart';
import '../mappers/ledger_mappers.dart';
import '../sync/supabase_ledger_remote_data_source.dart';

class DriftLedgerRepository implements LedgerRepository {
  static const requiredRemoteSchemaVersion = 2;

  DriftLedgerRepository({
    required LedgerDatabase database,
    required LedgerRemoteDataSource remoteDataSource,
    BillCalculator billCalculator = const BillCalculator(),
    SettlementCalculator settlementCalculator = const SettlementCalculator(),
  }) : this._(database, remoteDataSource, billCalculator, settlementCalculator);

  DriftLedgerRepository._(
    this._database,
    this._remoteDataSource,
    this._billCalculator,
    this._settlementCalculator,
  );

  final LedgerDatabase _database;
  final LedgerRemoteDataSource _remoteDataSource;
  final BillCalculator _billCalculator;
  final SettlementCalculator _settlementCalculator;

  @override
  Stream<LedgerOverview> watchOverview({
    required String userId,
    required String monthKey,
  }) {
    final query = _database.select(_database.serviceRecords)
      ..where(
        (table) =>
            table.userId.equals(userId) &
            table.monthKey.isSmallerOrEqualValue(monthKey) &
            table.isDeleted.equals(false),
      );

    return query.watch().asyncMap(
      (_) => getOverview(userId: userId, monthKey: monthKey),
    );
  }

  @override
  Future<LedgerOverview> getOverview({
    required String userId,
    required String monthKey,
  }) async {
    if (!_isLocalDevUser(userId)) {
      await syncRemoteChanges(userId: userId, monthKey: monthKey);
    }
    final services = await _loadServices(userId: userId, monthKey: monthKey);
    var totalPayable = 0;
    var advancePaid = 0;
    for (final service in services) {
      final bill = await getMonthlyBill(
        serviceId: service.id,
        monthKey: monthKey,
      );
      totalPayable += bill.payableAmountCents;
      advancePaid += bill.advanceAmountCents;
    }

    return LedgerOverview(
      profile: UserProfile(
        id: userId,
        name: userId == 'local-user' ? 'Local User' : 'Payqure User',
        email: userId == 'local-user' ? 'local@payqure.local' : '',
        phone: '',
        emailVerified: true,
      ),
      monthKey: monthKey,
      monthLabel: _monthLabel(monthKey),
      services: services,
      totalPayableCents: totalPayable,
      advancePaidCents: advancePaid,
    );
  }

  @override
  Future<String?> getLocalPreference(String key) async {
    final row = await (_database.select(
      _database.syncMetadataRecords,
    )..where((table) => table.id.equals('preference:$key'))).getSingleOrNull();
    return row?.entityType;
  }

  @override
  Future<void> saveLocalPreference({
    required String key,
    required String value,
  }) async {
    await _database
        .into(_database.syncMetadataRecords)
        .insertOnConflictUpdate(
          SyncMetadataRecordsCompanion.insert(
            id: 'preference:$key',
            entityType: value,
            lastSyncedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<HouseholdService> createService({
    required String userId,
    required String monthKey,
    required String name,
    required String description,
    required String icon,
    required String templateType,
    required String unit,
    required double defaultQuantity,
    required int rateCents,
    required int monthlyAmountCents,
  }) async {
    final now = DateTime.now();
    final service = ServiceRecordsCompanion.insert(
      id: IdGenerator.create('service'),
      userId: userId,
      monthKey: monthKey,
      name: name,
      description: description,
      icon: icon,
      templateType: templateType,
      unit: unit,
      defaultQuantity: Value(defaultQuantity),
      rateCents: rateCents,
      monthlyAmountCents: Value(monthlyAmountCents),
      updatedAt: now,
      pendingSync: const Value(true),
    );
    await _database.into(_database.serviceRecords).insert(service);
    await syncPending();
    final row = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.id.equals(service.id.value))).getSingle();
    return row.toDomain(const []);
  }

  @override
  Future<HouseholdService> updateService({
    required String id,
    required String name,
    required String description,
    required String unit,
    required double defaultQuantity,
    required int rateCents,
    required int monthlyAmountCents,
  }) async {
    await (_database.update(
      _database.serviceRecords,
    )..where((table) => table.id.equals(id))).write(
      ServiceRecordsCompanion(
        name: Value(name),
        description: Value(description),
        unit: Value(unit),
        defaultQuantity: Value(defaultQuantity),
        rateCents: Value(rateCents),
        monthlyAmountCents: Value(monthlyAmountCents),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
    await syncPending();
    final row = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.id.equals(id))).getSingle();
    final entries = await _loadEntries(row.id, row.monthKey);
    return row.toDomain(entries, activeMonthKey: row.monthKey);
  }

  @override
  Future<void> deleteService({
    required String serviceId,
    required String monthKey,
  }) async {
    await (_database.update(
      _database.serviceRecords,
    )..where((table) => table.id.equals(serviceId))).write(
      ServiceRecordsCompanion(
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
        isDeleted: const Value(true),
      ),
    );
    await syncPending();
  }

  @override
  Future<void> saveEntry(ServiceEntry entry) async {
    await _database
        .into(_database.entryRecords)
        .insertOnConflictUpdate(
          entry
              .copyWith(pendingSync: true, updatedAt: DateTime.now())
              .toCompanion(),
        );
    await _recalculateSettlement(
      serviceId: entry.serviceId,
      monthKey: entry.monthKey,
    );
    await syncPending();
  }

  @override
  Future<void> saveAdvance(AdvancePayment advance) async {
    await _database
        .into(_database.advancePaymentRecords)
        .insertOnConflictUpdate(
          AdvancePaymentRecordsCompanion.insert(
            id: advance.id,
            serviceId: advance.serviceId,
            monthKey: advance.monthKey,
            amountCents: advance.amountCents,
            paidOn: advance.paidOn,
            note: Value(advance.note),
            updatedAt: DateTime.now(),
            pendingSync: const Value(true),
          ),
        );
    await _recalculateSettlement(
      serviceId: advance.serviceId,
      monthKey: advance.monthKey,
    );
    await syncPending();
  }

  @override
  Future<List<AdvancePayment>> getAdvances({
    required String serviceId,
    required String monthKey,
  }) async {
    final rows =
        await (_database.select(_database.advancePaymentRecords)..where(
              (table) =>
                  table.serviceId.equals(serviceId) &
                  table.monthKey.equals(monthKey) &
                  table.isDeleted.equals(false),
            ))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> savePayment(PaymentTransaction payment) async {
    final next = payment.copyWith(pendingSync: true, updatedAt: DateTime.now());
    await _database
        .into(_database.paymentTransactionRecords)
        .insertOnConflictUpdate(next.toCompanion());
    await _recalculateSettlement(
      serviceId: payment.serviceId,
      monthKey: payment.monthKey,
    );
    await syncPending();
  }

  @override
  Future<void> deletePayment(PaymentTransaction payment) async {
    await _database
        .into(_database.paymentTransactionRecords)
        .insertOnConflictUpdate(
          payment
              .copyWith(
                isDeleted: true,
                pendingSync: true,
                updatedAt: DateTime.now(),
              )
              .toCompanion(),
        );
    await _recalculateSettlement(
      serviceId: payment.serviceId,
      monthKey: payment.monthKey,
    );
    await syncPending();
  }

  @override
  Future<List<PaymentTransaction>> getPayments({
    required String serviceId,
    required String monthKey,
  }) async {
    final rows =
        await (_database.select(_database.paymentTransactionRecords)
              ..where(
                (table) =>
                    table.serviceId.equals(serviceId) &
                    table.monthKey.equals(monthKey) &
                    table.isDeleted.equals(false),
              )
              ..orderBy([(table) => OrderingTerm.desc(table.paymentDate)]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String serviceId,
  }) async {
    final rows =
        await (_database.select(_database.paymentTransactionRecords)
              ..where(
                (table) =>
                    table.serviceId.equals(serviceId) &
                    table.isDeleted.equals(false),
              )
              ..orderBy([
                (table) => OrderingTerm.desc(table.monthKey),
                (table) => OrderingTerm.desc(table.paymentDate),
              ]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<MonthlySettlement> getSettlement({
    required String serviceId,
    required String monthKey,
  }) async {
    return _recalculateSettlement(serviceId: serviceId, monthKey: monthKey);
  }

  @override
  Future<MonthlyBill> getMonthlyBill({
    required String serviceId,
    required String monthKey,
  }) async {
    final service = await _loadService(serviceId, monthKey);
    final advances = await getAdvances(
      serviceId: serviceId,
      monthKey: monthKey,
    );
    final baseBill = _billCalculator.calculate(
      service: service,
      advances: advances,
    );
    final settlement = await _recalculateSettlement(
      serviceId: serviceId,
      monthKey: monthKey,
      service: service,
      advances: advances,
      baseGrossAmountCents: baseBill.grossAmountCents,
    );
    final payments = await getPayments(
      serviceId: serviceId,
      monthKey: monthKey,
    );
    return MonthlyBill(
      service: service,
      monthKey: monthKey,
      totalQuantity: baseBill.totalQuantity,
      grossAmountCents: baseBill.grossAmountCents,
      advanceAmountCents: settlement.advanceUsedCents,
      payableAmountCents: settlement.remainingAmountCents,
      lines: [
        BillLineItem(
          label: 'Gross Amount',
          amountCents: settlement.grossAmountCents,
        ),
        if (settlement.previousCarryForwardCents > 0)
          BillLineItem(
            label: 'Previous Due',
            amountCents: settlement.previousCarryForwardCents,
          ),
        if (settlement.advanceUsedCents > 0)
          BillLineItem(
            label: 'Less: Advance Used',
            amountCents: -settlement.advanceUsedCents,
          ),
        if (settlement.paidAmountCents > 0)
          BillLineItem(
            label: 'Less: Paid',
            amountCents: -settlement.paidAmountCents,
          ),
      ],
      advances: advances,
      payments: payments,
      settlement: settlement,
    );
  }

  @override
  Future<void> syncPending() async {
    if (!_remoteDataSource.isConfigured) {
      return;
    }
    await _ensureRemoteSchemaVersion();
    final services =
        await (_database.select(_database.serviceRecords)..where(
              (table) =>
                  table.pendingSync.equals(true) &
                  table.userId.equals('local-user').not(),
            ))
            .get();
    for (final row in services) {
      await _remoteDataSource.pushService(row);
      await (_database.update(_database.serviceRecords)
            ..where((table) => table.id.equals(row.id)))
          .write(const ServiceRecordsCompanion(pendingSync: Value(false)));
    }

    final entries = await (_database.select(
      _database.entryRecords,
    )..where((table) => table.pendingSync.equals(true))).get();
    final localServiceIds = await _localDevServiceIds();
    for (final row in entries) {
      if (localServiceIds.contains(row.serviceId)) {
        continue;
      }
      await _remoteDataSource.pushEntry(row);
      await (_database.update(_database.entryRecords)
            ..where((table) => table.id.equals(row.id)))
          .write(const EntryRecordsCompanion(pendingSync: Value(false)));
    }

    final advances = await (_database.select(
      _database.advancePaymentRecords,
    )..where((table) => table.pendingSync.equals(true))).get();
    for (final row in advances) {
      if (localServiceIds.contains(row.serviceId)) {
        continue;
      }
      await _remoteDataSource.pushAdvance(row);
      await (_database.update(
        _database.advancePaymentRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const AdvancePaymentRecordsCompanion(pendingSync: Value(false)),
      );
    }

    final payments = await (_database.select(
      _database.paymentTransactionRecords,
    )..where((table) => table.pendingSync.equals(true))).get();
    for (final row in payments) {
      if (localServiceIds.contains(row.serviceId)) {
        continue;
      }
      await _remoteDataSource.pushPayment(row);
      await (_database.update(
        _database.paymentTransactionRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const PaymentTransactionRecordsCompanion(pendingSync: Value(false)),
      );
    }

    final settlements = await (_database.select(
      _database.monthlySettlementRecords,
    )..where((table) => table.pendingSync.equals(true))).get();
    for (final row in settlements) {
      if (localServiceIds.contains(row.serviceId)) {
        continue;
      }
      await _remoteDataSource.pushSettlement(row);
      await (_database.update(
        _database.monthlySettlementRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const MonthlySettlementRecordsCompanion(pendingSync: Value(false)),
      );
    }
  }

  @override
  Future<void> syncUserDataAndClearLocal({required String userId}) async {
    if (!_remoteDataSource.isConfigured) {
      throw StateError('Supabase is not configured for remote sync.');
    }
    if (_isLocalDevUser(userId)) {
      throw StateError('Sign in with Supabase before syncing local data.');
    }

    await _ensureRemoteSchemaVersion();
    await _claimLocalDevRowsForUser(userId);
    await _pushAllRowsForUser(userId);
    await _clearLocalData();
  }

  @override
  Future<void> syncRemoteChanges({
    required String userId,
    required String monthKey,
  }) async {
    if (!_remoteDataSource.isConfigured || _isLocalDevUser(userId)) {
      return;
    }
    await _ensureRemoteSchemaVersion();

    final services = await _remoteDataSource.fetchServices(
      userId: userId,
      monthKey: monthKey,
    );
    final entries = await _remoteDataSource.fetchEntries(monthKey: monthKey);
    final advances = await _remoteDataSource.fetchAdvances(monthKey: monthKey);
    final payments = await _remoteDataSource.fetchPayments(monthKey: monthKey);
    final settlements = await _remoteDataSource.fetchSettlements(
      monthKey: monthKey,
    );

    await _database.transaction(() async {
      for (final row in services) {
        final updatedAt = _date(row['updated_at']);
        if (!await _shouldApplyRemoteService(row['id'].toString(), updatedAt)) {
          continue;
        }
        await _database
            .into(_database.serviceRecords)
            .insertOnConflictUpdate(
              ServiceRecordsCompanion.insert(
                id: row['id'].toString(),
                userId: row['user_id'].toString(),
                monthKey: row['month_key'].toString(),
                name: row['name'].toString(),
                description: row['description'].toString(),
                icon: row['icon'].toString(),
                templateType: row['template_type'].toString(),
                unit: row['unit']?.toString() ?? '',
                defaultQuantity: Value(_double(row['default_quantity'], 1)),
                rateCents: _int(row['rate_cents']),
                monthlyAmountCents: Value(_int(row['monthly_amount_cents'])),
                updatedAt: updatedAt,
                pendingSync: const Value(false),
                isDeleted: Value(_bool(row['is_deleted'])),
              ),
            );
      }

      for (final row in entries) {
        final updatedAt = _date(row['updated_at']);
        if (!await _shouldApplyRemoteEntry(row['id'].toString(), updatedAt)) {
          continue;
        }
        await _database
            .into(_database.entryRecords)
            .insertOnConflictUpdate(
              EntryRecordsCompanion.insert(
                id: row['id'].toString(),
                serviceId: row['service_id'].toString(),
                monthKey: row['month_key'].toString(),
                day: _int(row['day']),
                status: row['status'].toString(),
                quantity: Value(_double(row['quantity'], 0)),
                unit: Value(row['unit']?.toString() ?? ''),
                rateCents: Value(_int(row['rate_cents'])),
                amountCents: Value(_int(row['amount_cents'])),
                note: Value(row['note']?.toString() ?? ''),
                updatedAt: updatedAt,
                pendingSync: const Value(false),
                isDeleted: Value(_bool(row['is_deleted'])),
              ),
            );
      }

      for (final row in advances) {
        final updatedAt = _date(row['updated_at']);
        if (!await _shouldApplyRemoteAdvance(row['id'].toString(), updatedAt)) {
          continue;
        }
        await _database
            .into(_database.advancePaymentRecords)
            .insertOnConflictUpdate(
              AdvancePaymentRecordsCompanion.insert(
                id: row['id'].toString(),
                serviceId: row['service_id'].toString(),
                monthKey: row['month_key'].toString(),
                amountCents: _int(row['amount_cents']),
                paidOn: _date(row['paid_on']),
                note: Value(row['note']?.toString() ?? ''),
                updatedAt: updatedAt,
                pendingSync: const Value(false),
                isDeleted: Value(_bool(row['is_deleted'])),
              ),
            );
      }

      for (final row in payments) {
        final updatedAt = _date(row['updated_at']);
        await _database
            .into(_database.paymentTransactionRecords)
            .insertOnConflictUpdate(
              PaymentTransactionRecordsCompanion.insert(
                id: row['id'].toString(),
                userId: row['user_id'].toString(),
                serviceId: row['service_id'].toString(),
                monthKey: row['month_key'].toString(),
                amountCents: _int(row['amount_cents']),
                paymentDate: _date(row['payment_date']),
                paymentMode: row['payment_mode'].toString(),
                note: Value(row['note']?.toString() ?? ''),
                createdAt: _date(row['created_at']),
                updatedAt: updatedAt,
                pendingSync: const Value(false),
                isDeleted: Value(_bool(row['is_deleted'])),
              ),
            );
      }

      for (final row in settlements) {
        final updatedAt = _date(row['updated_at']);
        await _database
            .into(_database.monthlySettlementRecords)
            .insertOnConflictUpdate(
              MonthlySettlementRecordsCompanion.insert(
                id: row['id'].toString(),
                userId: row['user_id'].toString(),
                serviceId: row['service_id'].toString(),
                monthKey: row['month_key'].toString(),
                grossAmountCents: Value(_int(row['gross_amount_cents'])),
                advanceUsedCents: Value(_int(row['advance_used_cents'])),
                previousCarryForwardCents: Value(
                  _int(row['previous_carry_forward_cents']),
                ),
                previousAdvanceCents: Value(
                  _int(row['previous_advance_cents']),
                ),
                payableAmountCents: Value(_int(row['payable_amount_cents'])),
                paidAmountCents: Value(_int(row['paid_amount_cents'])),
                remainingAmountCents: Value(
                  _int(row['remaining_amount_cents']),
                ),
                carryForwardToNextMonthCents: Value(
                  _int(row['carry_forward_to_next_month_cents']),
                ),
                advanceToNextMonthCents: Value(
                  _int(row['advance_to_next_month_cents']),
                ),
                status: row['status'].toString(),
                generatedAt: _date(row['generated_at']),
                updatedAt: updatedAt,
                pendingSync: const Value(false),
                isDeleted: Value(_bool(row['is_deleted'])),
              ),
            );
      }
    });
  }

  Future<MonthlySettlement> _recalculateSettlement({
    required String serviceId,
    required String monthKey,
    HouseholdService? service,
    List<AdvancePayment>? advances,
    int? baseGrossAmountCents,
  }) async {
    final activeService = service ?? await _loadService(serviceId, monthKey);
    final activeAdvances =
        advances ??
        await getAdvances(serviceId: activeService.id, monthKey: monthKey);
    final gross =
        baseGrossAmountCents ??
        _billCalculator
            .calculate(service: activeService, advances: activeAdvances)
            .grossAmountCents;
    final payments = await getPayments(
      serviceId: serviceId,
      monthKey: monthKey,
    );
    final previousSettlement = await _loadSettlement(
      serviceId: serviceId,
      monthKey: _previousMonthKey(monthKey),
    );
    final settlement = _settlementCalculator.calculate(
      userId: activeService.userId,
      serviceId: serviceId,
      monthKey: monthKey,
      grossAmountCents: gross,
      manualAdvanceCents: activeAdvances.fold<int>(
        0,
        (sum, advance) => sum + advance.amountCents,
      ),
      payments: payments,
      previousSettlement: previousSettlement,
    );
    await _database
        .into(_database.monthlySettlementRecords)
        .insertOnConflictUpdate(settlement.toCompanion());
    return settlement;
  }

  Future<MonthlySettlement?> _loadSettlement({
    required String serviceId,
    required String monthKey,
  }) async {
    final row =
        await (_database.select(_database.monthlySettlementRecords)..where(
              (table) =>
                  table.serviceId.equals(serviceId) &
                  table.monthKey.equals(monthKey) &
                  table.isDeleted.equals(false),
            ))
            .getSingleOrNull();
    return row?.toDomain();
  }

  Future<bool> _shouldApplyRemoteService(String id, DateTime remoteUpdatedAt) {
    return _shouldApplyRemote(
      id: id,
      remoteUpdatedAt: remoteUpdatedAt,
      tableUpdatedAt: (id) async {
        final row = await (_database.select(
          _database.serviceRecords,
        )..where((table) => table.id.equals(id))).getSingleOrNull();
        return row == null
            ? null
            : _LocalSyncState(row.updatedAt, row.pendingSync);
      },
    );
  }

  Future<void> _ensureRemoteSchemaVersion() async {
    final version = await _remoteDataSource.fetchSchemaVersion();
    if (version == null || version < requiredRemoteSchemaVersion) {
      throw StateError(
        'Supabase ledger schema is not ready. Apply the latest migration.',
      );
    }
  }

  bool _isLocalDevUser(String userId) {
    return userId == 'local-user';
  }

  Future<void> _claimLocalDevRowsForUser(String userId) async {
    final localServices = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.userId.equals('local-user'))).get();
    if (localServices.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final localServiceIds = localServices.map((row) => row.id).toSet();
    await _database.transaction(() async {
      await (_database.update(
        _database.serviceRecords,
      )..where((table) => table.userId.equals('local-user'))).write(
        ServiceRecordsCompanion(
          userId: Value(userId),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
      await (_database.update(
        _database.paymentTransactionRecords,
      )..where((table) => table.userId.equals('local-user'))).write(
        PaymentTransactionRecordsCompanion(
          userId: Value(userId),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
      await (_database.update(
        _database.monthlySettlementRecords,
      )..where((table) => table.userId.equals('local-user'))).write(
        MonthlySettlementRecordsCompanion(
          userId: Value(userId),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

      if (localServiceIds.isNotEmpty) {
        await (_database.update(
          _database.entryRecords,
        )..where((table) => table.serviceId.isIn(localServiceIds))).write(
          EntryRecordsCompanion(
            updatedAt: Value(now),
            pendingSync: const Value(true),
          ),
        );
        await (_database.update(
          _database.advancePaymentRecords,
        )..where((table) => table.serviceId.isIn(localServiceIds))).write(
          AdvancePaymentRecordsCompanion(
            updatedAt: Value(now),
            pendingSync: const Value(true),
          ),
        );
      }
    });
  }

  Future<void> _pushAllRowsForUser(String userId) async {
    final services = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.userId.equals(userId))).get();
    final serviceIds = services.map((row) => row.id).toSet();

    for (final row in services) {
      await _remoteDataSource.pushService(row);
      await (_database.update(_database.serviceRecords)
            ..where((table) => table.id.equals(row.id)))
          .write(const ServiceRecordsCompanion(pendingSync: Value(false)));
    }

    if (serviceIds.isEmpty) {
      return;
    }

    final entries = await (_database.select(
      _database.entryRecords,
    )..where((table) => table.serviceId.isIn(serviceIds))).get();
    for (final row in entries) {
      await _remoteDataSource.pushEntry(row);
      await (_database.update(_database.entryRecords)
            ..where((table) => table.id.equals(row.id)))
          .write(const EntryRecordsCompanion(pendingSync: Value(false)));
    }

    final advances = await (_database.select(
      _database.advancePaymentRecords,
    )..where((table) => table.serviceId.isIn(serviceIds))).get();
    for (final row in advances) {
      await _remoteDataSource.pushAdvance(row);
      await (_database.update(
        _database.advancePaymentRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const AdvancePaymentRecordsCompanion(pendingSync: Value(false)),
      );
    }

    final payments = await (_database.select(
      _database.paymentTransactionRecords,
    )..where((table) => table.userId.equals(userId))).get();
    for (final row in payments) {
      await _remoteDataSource.pushPayment(row);
      await (_database.update(
        _database.paymentTransactionRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const PaymentTransactionRecordsCompanion(pendingSync: Value(false)),
      );
    }

    final settlements = await (_database.select(
      _database.monthlySettlementRecords,
    )..where((table) => table.userId.equals(userId))).get();
    for (final row in settlements) {
      await _remoteDataSource.pushSettlement(row);
      await (_database.update(
        _database.monthlySettlementRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const MonthlySettlementRecordsCompanion(pendingSync: Value(false)),
      );
    }
  }

  Future<void> _clearLocalData() async {
    await _database.transaction(() async {
      await _database.delete(_database.entryRecords).go();
      await _database.delete(_database.advancePaymentRecords).go();
      await _database.delete(_database.paymentTransactionRecords).go();
      await _database.delete(_database.monthlySettlementRecords).go();
      await _database.delete(_database.serviceRecords).go();
      await _database.delete(_database.profileRecords).go();
      await _database.delete(_database.syncMetadataRecords).go();
    });
  }

  Future<Set<String>> _localDevServiceIds() async {
    final rows = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.userId.equals('local-user'))).get();
    return rows.map((row) => row.id).toSet();
  }

  Future<bool> _shouldApplyRemoteEntry(String id, DateTime remoteUpdatedAt) {
    return _shouldApplyRemote(
      id: id,
      remoteUpdatedAt: remoteUpdatedAt,
      tableUpdatedAt: (id) async {
        final row = await (_database.select(
          _database.entryRecords,
        )..where((table) => table.id.equals(id))).getSingleOrNull();
        return row == null
            ? null
            : _LocalSyncState(row.updatedAt, row.pendingSync);
      },
    );
  }

  Future<bool> _shouldApplyRemoteAdvance(String id, DateTime remoteUpdatedAt) {
    return _shouldApplyRemote(
      id: id,
      remoteUpdatedAt: remoteUpdatedAt,
      tableUpdatedAt: (id) async {
        final row = await (_database.select(
          _database.advancePaymentRecords,
        )..where((table) => table.id.equals(id))).getSingleOrNull();
        return row == null
            ? null
            : _LocalSyncState(row.updatedAt, row.pendingSync);
      },
    );
  }

  Future<bool> _shouldApplyRemote({
    required String id,
    required DateTime remoteUpdatedAt,
    required Future<_LocalSyncState?> Function(String id) tableUpdatedAt,
  }) async {
    final local = await tableUpdatedAt(id);
    if (local == null) {
      return true;
    }
    if (local.pendingSync && local.updatedAt.isAfter(remoteUpdatedAt)) {
      return false;
    }
    return remoteUpdatedAt.isAfter(local.updatedAt);
  }

  Future<List<HouseholdService>> _loadServices({
    required String userId,
    required String monthKey,
  }) async {
    final rows =
        await (_database.select(_database.serviceRecords)..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.monthKey.isSmallerOrEqualValue(monthKey) &
                  table.isDeleted.equals(false),
            ))
            .get();
    final services = <HouseholdService>[];
    for (final row in rows) {
      final entries = await _loadEntries(row.id, monthKey);
      services.add(row.toDomain(entries, activeMonthKey: monthKey));
    }
    return services;
  }

  Future<HouseholdService> _loadService(String id, String monthKey) async {
    final row = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.id.equals(id))).getSingle();
    final entries = await _loadEntries(row.id, monthKey);
    return row.toDomain(entries, activeMonthKey: monthKey);
  }

  Future<List<ServiceEntry>> _loadEntries(
    String serviceId,
    String monthKey,
  ) async {
    final rows =
        await (_database.select(_database.entryRecords)
              ..where(
                (table) =>
                    table.serviceId.equals(serviceId) &
                    table.monthKey.equals(monthKey) &
                    table.isDeleted.equals(false),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.day)]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  String _monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) {
      return monthKey;
    }
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${months[month - 1]} ${parts[0]}';
  }

  DateTime _date(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  String _previousMonthKey(String key) {
    final parts = key.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    final previous = DateTime(year, month - 1);
    return '${previous.year}-${previous.month.toString().padLeft(2, '0')}';
  }

  int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _double(Object? value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _bool(Object? value) {
    if (value is bool) {
      return value;
    }
    return value?.toString() == 'true';
  }
}

class _LocalSyncState {
  const _LocalSyncState(this.updatedAt, this.pendingSync);

  final DateTime updatedAt;
  final bool pendingSync;
}
