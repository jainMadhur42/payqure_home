import 'package:drift/drift.dart';

import '../../domain/entities/service_metadata.dart';
import '../database/ledger_database.dart';
import 'supabase_ledger_remote_data_source.dart';

class DriftLedgerSyncService {
  const DriftLedgerSyncService({
    required LedgerDatabase database,
    required LedgerRemoteDataSource remoteDataSource,
  }) : this._(database, remoteDataSource);

  const DriftLedgerSyncService._(this._database, this._remoteDataSource);

  final LedgerDatabase _database;
  final LedgerRemoteDataSource _remoteDataSource;

  bool get isConfigured => _remoteDataSource.isConfigured;

  Future<int?> fetchSchemaVersion() {
    return _remoteDataSource.fetchSchemaVersion();
  }

  bool isLocalDevelopmentUser(String userId) => userId == 'local-user';

  Future<void> performPendingSync() async {
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

    final localServiceIds = await _localDevelopmentServiceIds();
    final monthLogs = await (_database.select(
      _database.serviceMonthLogRecords,
    )..where((table) => table.pendingSync.equals(true))).get();
    for (final row in monthLogs) {
      if (localServiceIds.contains(row.serviceId)) {
        continue;
      }
      await _remoteDataSource.pushMonthLog(row);
      await (_database.update(
        _database.serviceMonthLogRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const ServiceMonthLogRecordsCompanion(pendingSync: Value(false)),
      );
    }

    final entries = await (_database.select(
      _database.entryRecords,
    )..where((table) => table.pendingSync.equals(true))).get();
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

  Future<void> pullMonth({
    required String userId,
    required String monthKey,
  }) async {
    final results = await Future.wait<Object>([
      _remoteDataSource.fetchServices(userId: userId, monthKey: monthKey),
      _remoteDataSource.fetchMonthLogs(monthKey: monthKey),
      _remoteDataSource.fetchEntries(monthKey: monthKey),
      _remoteDataSource.fetchAdvances(monthKey: monthKey),
      _remoteDataSource.fetchPayments(monthKey: monthKey),
      _remoteDataSource.fetchSettlements(monthKey: monthKey),
    ]);
    final services = results[0] as List<Map<String, dynamic>>;
    final monthLogs = results[1] as List<Map<String, dynamic>>;
    final entries = results[2] as List<Map<String, dynamic>>;
    final advances = results[3] as List<Map<String, dynamic>>;
    final payments = results[4] as List<Map<String, dynamic>>;
    final settlements = results[5] as List<Map<String, dynamic>>;

    await _database.transaction(() async {
      await _mergeServices(services);
      await _mergeMonthLogs(monthLogs);
      await _mergeEntries(entries);
      await _mergeAdvances(advances);
      await _mergePayments(payments);
      await _mergeSettlements(settlements);
    });
  }

  Future<bool> isMonthCached({
    required String userId,
    required String monthKey,
  }) async {
    if (isLocalDevelopmentUser(userId)) {
      return true;
    }
    final row =
        await (_database.select(_database.syncMetadataRecords)..where(
              (table) =>
                  table.id.equals(_monthCacheId(userId, monthKey)) &
                  table.entityType.equals('remote_month_cache'),
            ))
            .getSingleOrNull();
    return row?.lastSyncedAt != null;
  }

  Future<void> markMonthCached({
    required String userId,
    required String monthKey,
  }) async {
    await _database
        .into(_database.syncMetadataRecords)
        .insertOnConflictUpdate(
          SyncMetadataRecordsCompanion.insert(
            id: _monthCacheId(userId, monthKey),
            entityType: 'remote_month_cache',
            lastSyncedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> transferUserDataAndClearLocal(String userId) async {
    await _claimLocalDevelopmentRows(userId);
    await _pushAllRowsForUser(userId);
    await _clearLocalData();
  }

  Future<void> _mergeServices(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final updatedAt = _date(row['updated_at']);
      final id = row['id'].toString();
      if (!await _shouldApplyRemote(
        id: id,
        remoteUpdatedAt: updatedAt,
        localState: _serviceSyncState,
      )) {
        continue;
      }
      final storedMonthKey = row['month_key'].toString();
      final effectiveMonthKey = _effectiveServiceMonthKey(
        storedMonthKey: storedMonthKey,
        description: row['description']?.toString() ?? '',
      );
      await _database
          .into(_database.serviceRecords)
          .insertOnConflictUpdate(
            ServiceRecordsCompanion.insert(
              id: id,
              userId: row['user_id'].toString(),
              monthKey: effectiveMonthKey,
              name: row['name'].toString(),
              description: row['description']?.toString() ?? '',
              icon: row['icon'].toString(),
              templateType: row['template_type'].toString(),
              unit: row['unit']?.toString() ?? '',
              defaultQuantity: Value(_double(row['default_quantity'], 1)),
              rateCents: _int(row['rate_cents']),
              monthlyAmountCents: Value(_int(row['monthly_amount_cents'])),
              updatedAt: updatedAt,
              pendingSync: Value(effectiveMonthKey != storedMonthKey),
              isDeleted: Value(_bool(row['is_deleted'])),
            ),
          );
    }
  }

  Future<void> _mergeEntries(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final updatedAt = _date(row['updated_at']);
      final id = row['id'].toString();
      if (!await _shouldApplyRemote(
        id: id,
        remoteUpdatedAt: updatedAt,
        localState: _entrySyncState,
      )) {
        continue;
      }
      await _database
          .into(_database.entryRecords)
          .insertOnConflictUpdate(
            EntryRecordsCompanion.insert(
              id: id,
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
  }

  Future<void> _mergeMonthLogs(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final updatedAt = _date(row['updated_at']);
      final id = row['id'].toString();
      if (!await _shouldApplyRemote(
        id: id,
        remoteUpdatedAt: updatedAt,
        localState: _monthLogSyncState,
      )) {
        continue;
      }
      await _database
          .into(_database.serviceMonthLogRecords)
          .insertOnConflictUpdate(
            ServiceMonthLogRecordsCompanion.insert(
              id: id,
              serviceId: row['service_id'].toString(),
              monthKey: row['month_key'].toString(),
              schemaVersion: Value(_int(row['schema_version'])),
              entriesJson: Value(
                row['entries_json']?.toString() ??
                    '{"schemaVersion":1,"overrides":{}}',
              ),
              updatedAt: updatedAt,
              pendingSync: const Value(false),
              isDeleted: Value(_bool(row['is_deleted'])),
            ),
          );
    }
  }

  Future<void> _mergeAdvances(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final updatedAt = _date(row['updated_at']);
      final id = row['id'].toString();
      if (!await _shouldApplyRemote(
        id: id,
        remoteUpdatedAt: updatedAt,
        localState: _advanceSyncState,
      )) {
        continue;
      }
      await _database
          .into(_database.advancePaymentRecords)
          .insertOnConflictUpdate(
            AdvancePaymentRecordsCompanion.insert(
              id: id,
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
  }

  Future<void> _mergePayments(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
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
              currentMonthAmountCents: Value(
                _int(row['current_month_amount_cents']),
              ),
              previousBalanceAmountCents: Value(
                _int(row['previous_balance_amount_cents']),
              ),
              advanceAmountCents: Value(_int(row['advance_amount_cents'])),
              createdAt: _date(row['created_at']),
              updatedAt: _date(row['updated_at']),
              pendingSync: const Value(false),
              isDeleted: Value(_bool(row['is_deleted'])),
            ),
          );
    }
  }

  Future<void> _mergeSettlements(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
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
              previousAdvanceCents: Value(_int(row['previous_advance_cents'])),
              payableAmountCents: Value(_int(row['payable_amount_cents'])),
              paidAmountCents: Value(_int(row['paid_amount_cents'])),
              remainingAmountCents: Value(_int(row['remaining_amount_cents'])),
              carryForwardToNextMonthCents: Value(
                _int(row['carry_forward_to_next_month_cents']),
              ),
              advanceToNextMonthCents: Value(
                _int(row['advance_to_next_month_cents']),
              ),
              status: row['status'].toString(),
              generatedAt: _date(row['generated_at']),
              updatedAt: _date(row['updated_at']),
              pendingSync: const Value(false),
              isDeleted: Value(_bool(row['is_deleted'])),
            ),
          );
    }
  }

  Future<void> _claimLocalDevelopmentRows(String userId) async {
    final localServices = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.userId.equals('local-user'))).get();
    if (localServices.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final serviceIds = localServices.map((row) => row.id).toSet();
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
      await (_database.update(
        _database.entryRecords,
      )..where((table) => table.serviceId.isIn(serviceIds))).write(
        EntryRecordsCompanion(
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
      await (_database.update(
        _database.serviceMonthLogRecords,
      )..where((table) => table.serviceId.isIn(serviceIds))).write(
        ServiceMonthLogRecordsCompanion(
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
      await (_database.update(
        _database.advancePaymentRecords,
      )..where((table) => table.serviceId.isIn(serviceIds))).write(
        AdvancePaymentRecordsCompanion(
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
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
    final monthLogs = await (_database.select(
      _database.serviceMonthLogRecords,
    )..where((table) => table.serviceId.isIn(serviceIds))).get();
    for (final row in monthLogs) {
      await _remoteDataSource.pushMonthLog(row);
      await (_database.update(
        _database.serviceMonthLogRecords,
      )..where((table) => table.id.equals(row.id))).write(
        const ServiceMonthLogRecordsCompanion(pendingSync: Value(false)),
      );
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

  Future<void> _clearLocalData() {
    return _database.transaction(() async {
      await _database.delete(_database.entryRecords).go();
      await _database.delete(_database.serviceMonthLogRecords).go();
      await _database.delete(_database.advancePaymentRecords).go();
      await _database.delete(_database.paymentTransactionRecords).go();
      await _database.delete(_database.monthlySettlementRecords).go();
      await _database.delete(_database.serviceRecords).go();
      await _database.delete(_database.profileRecords).go();
      await _database.delete(_database.syncMetadataRecords).go();
    });
  }

  Future<Set<String>> _localDevelopmentServiceIds() async {
    final rows = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.userId.equals('local-user'))).get();
    return rows.map((row) => row.id).toSet();
  }

  Future<_LocalSyncState?> _serviceSyncState(String id) async {
    final row = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _LocalSyncState(row.updatedAt, row.pendingSync);
  }

  Future<_LocalSyncState?> _entrySyncState(String id) async {
    final row = await (_database.select(
      _database.entryRecords,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _LocalSyncState(row.updatedAt, row.pendingSync);
  }

  Future<_LocalSyncState?> _monthLogSyncState(String id) async {
    final row = await (_database.select(
      _database.serviceMonthLogRecords,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _LocalSyncState(row.updatedAt, row.pendingSync);
  }

  Future<_LocalSyncState?> _advanceSyncState(String id) async {
    final row = await (_database.select(
      _database.advancePaymentRecords,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _LocalSyncState(row.updatedAt, row.pendingSync);
  }

  Future<bool> _shouldApplyRemote({
    required String id,
    required DateTime remoteUpdatedAt,
    required Future<_LocalSyncState?> Function(String id) localState,
  }) async {
    final local = await localState(id);
    if (local == null) {
      return true;
    }
    if (local.pendingSync && local.updatedAt.isAfter(remoteUpdatedAt)) {
      return false;
    }
    return remoteUpdatedAt.isAfter(local.updatedAt);
  }

  String _effectiveServiceMonthKey({
    required String storedMonthKey,
    required String description,
  }) {
    final startDate = ServiceMetadata.parse(description).startDate;
    if (startDate == null) {
      return storedMonthKey;
    }
    return '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
  }

  String _monthCacheId(String userId, String monthKey) {
    return 'remote-month:$userId:$monthKey';
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
