import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/advance_payment.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_overview.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/payment_settlement_preview.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_metadata.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/bill_calculator.dart';
import '../../domain/services/payment_allocation_calculator.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../../domain/services/settlement_calculator.dart';
import '../database/ledger_database.dart';
import '../mappers/ledger_mappers.dart';
import '../sync/drift_ledger_sync_service.dart';
import '../sync/ledger_sync_coordinator.dart';
import '../sync/supabase_ledger_remote_data_source.dart';

class DriftLedgerRepository implements LedgerRepository {
  static const requiredRemoteSchemaVersion = 4;

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
  ) {
    _syncService = DriftLedgerSyncService(
      database: _database,
      remoteDataSource: _remoteDataSource,
    );
    _syncCoordinator = LedgerSyncCoordinator(
      requiredSchemaVersion: requiredRemoteSchemaVersion,
      fetchSchemaVersion: _syncService.fetchSchemaVersion,
      performPendingSync: _syncService.performPendingSync,
    );
  }

  final LedgerDatabase _database;
  final LedgerRemoteDataSource _remoteDataSource;
  final BillCalculator _billCalculator;
  final SettlementCalculator _settlementCalculator;
  final PaymentAllocationCalculator _paymentAllocationCalculator =
      const PaymentAllocationCalculator();
  final ServiceStartDateResolver _serviceStartDateResolver =
      const ServiceStartDateResolver();
  final Map<String, Future<void>> _entityOperationGates = {};
  late final DriftLedgerSyncService _syncService;
  late final LedgerSyncCoordinator _syncCoordinator;

  @override
  Stream<LedgerOverview> watchOverview({
    required String userId,
    required String monthKey,
  }) {
    return _watchLedgerChanges(
      userId,
    ).asyncMap((_) => getOverview(userId: userId, monthKey: monthKey));
  }

  @override
  Future<LedgerOverview> getOverview({
    required String userId,
    required String monthKey,
  }) async {
    final services = await _loadServices(userId: userId, monthKey: monthKey);
    final totals = await _loadOverviewTotals(
      userId: userId,
      monthKey: monthKey,
      serviceIds: services.map((service) => service.id).toSet(),
    );

    return LedgerOverview(
      profile: UserProfile(
        id: userId,
        name: userId == 'local-user' ? 'Local User' : 'Payqure User',
        email: userId == 'local-user' ? 'local@payqure.local' : '',
        phone: '',
        emailVerified: true,
        privacyPolicyAccepted: true,
        privacyPolicyAcceptedAt: DateTime.now(),
        privacyPolicyVersion: '2026-06',
      ),
      monthKey: monthKey,
      monthLabel: _monthLabel(monthKey),
      services: services,
      totalPayableCents: totals.totalPayableCents,
      advancePaidCents: totals.advancePaidCents,
    );
  }

  Stream<void> _watchLedgerChanges(String userId) {
    late final StreamController<void> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    Timer? notificationTimer;

    void emit(dynamic _) {
      notificationTimer?.cancel();
      notificationTimer = Timer(const Duration(milliseconds: 16), () {
        if (!controller.isClosed) {
          controller.add(null);
        }
      });
    }

    void emitError(Object error, StackTrace stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<void>(
      onListen: () {
        final services = _database.select(_database.serviceRecords)
          ..where((table) => table.userId.equals(userId));
        final payments = _database.select(_database.paymentTransactionRecords)
          ..where((table) => table.userId.equals(userId));
        final settlements = _database.select(_database.monthlySettlementRecords)
          ..where((table) => table.userId.equals(userId));
        final entries = _database.select(_database.entryRecords).join([
          innerJoin(
            _database.serviceRecords,
            _database.serviceRecords.id.equalsExp(
              _database.entryRecords.serviceId,
            ),
          ),
        ])..where(_database.serviceRecords.userId.equals(userId));
        final advances =
            _database.select(_database.advancePaymentRecords).join([
              innerJoin(
                _database.serviceRecords,
                _database.serviceRecords.id.equalsExp(
                  _database.advancePaymentRecords.serviceId,
                ),
              ),
            ])..where(_database.serviceRecords.userId.equals(userId));

        subscriptions
          ..add(services.watch().listen(emit, onError: emitError))
          ..add(entries.watch().listen(emit, onError: emitError))
          ..add(advances.watch().listen(emit, onError: emitError))
          ..add(payments.watch().listen(emit, onError: emitError))
          ..add(settlements.watch().listen(emit, onError: emitError));
      },
      onCancel: () async {
        notificationTimer?.cancel();
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      },
    );
    return controller.stream;
  }

  Future<_OverviewTotals> _loadOverviewTotals({
    required String userId,
    required String monthKey,
    required Set<String> serviceIds,
  }) async {
    if (serviceIds.isEmpty) {
      return const _OverviewTotals();
    }
    final settlements =
        await (_database.select(_database.monthlySettlementRecords)..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.monthKey.equals(monthKey) &
                  table.serviceId.isIn(serviceIds) &
                  table.isDeleted.equals(false),
            ))
            .get();
    final followingPayments =
        await (_database.select(_database.paymentTransactionRecords)..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.monthKey.isBiggerThanValue(monthKey) &
                  table.serviceId.isIn(serviceIds) &
                  table.isDeleted.equals(false),
            ))
            .get();
    final paidFromFollowingMonth = <String, int>{};
    for (final payment in followingPayments) {
      paidFromFollowingMonth.update(
        payment.serviceId,
        (value) => value + payment.previousBalanceAmountCents,
        ifAbsent: () => payment.previousBalanceAmountCents,
      );
    }

    var totalPayableCents = 0;
    var advancePaidCents = 0;
    for (final settlement in settlements) {
      final laterPayment = paidFromFollowingMonth[settlement.serviceId] ?? 0;
      totalPayableCents += (settlement.remainingAmountCents - laterPayment)
          .clamp(0, settlement.remainingAmountCents)
          .toInt();
      advancePaidCents += settlement.advanceUsedCents;
    }
    return _OverviewTotals(
      totalPayableCents: totalPayableCents,
      advancePaidCents: advancePaidCents,
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
    _scheduleSync();
    final row = await (_database.select(
      _database.serviceRecords,
    )..where((table) => table.id.equals(service.id.value))).getSingle();
    return row.toDomain(const []);
  }

  @override
  Future<HouseholdService> updateService({
    required String id,
    required String monthKey,
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
        monthKey: Value(monthKey),
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
    _scheduleSync();
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
    _scheduleSync();
  }

  @override
  Future<void> saveEntry(ServiceEntry entry) async {
    await _runForService(entry.serviceId, () async {
      await _database.transaction(() async {
        await _database
            .into(_database.entryRecords)
            .insertOnConflictUpdate(
              entry
                  .copyWith(pendingSync: true, updatedAt: DateTime.now())
                  .toCompanion(),
            );
        await _reallocatePayments(
          serviceId: entry.serviceId,
          monthKey: entry.monthKey,
        );
        await _recalculateSettlement(
          serviceId: entry.serviceId,
          monthKey: entry.monthKey,
        );
      });
    });
    _scheduleSync();
  }

  @override
  Future<void> saveAdvance(AdvancePayment advance) async {
    await _runForService(advance.serviceId, () async {
      await _database.transaction(() async {
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
        await _reallocatePayments(
          serviceId: advance.serviceId,
          monthKey: advance.monthKey,
        );
        await _recalculateSettlement(
          serviceId: advance.serviceId,
          monthKey: advance.monthKey,
        );
      });
    });
    _scheduleSync();
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
  Future<List<AdvancePayment>> getAdvanceHistory({
    required String serviceId,
  }) async {
    final rows =
        await (_database.select(_database.advancePaymentRecords)
              ..where(
                (table) =>
                    table.serviceId.equals(serviceId) &
                    table.isDeleted.equals(false),
              )
              ..orderBy([(table) => OrderingTerm.desc(table.paidOn)]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> savePayment(PaymentTransaction payment) async {
    final next = payment.copyWith(pendingSync: true, updatedAt: DateTime.now());
    await _runForService(payment.serviceId, () async {
      await _database.transaction(() async {
        await _database
            .into(_database.paymentTransactionRecords)
            .insertOnConflictUpdate(next.toCompanion());
        await _reallocatePayments(
          serviceId: payment.serviceId,
          monthKey: payment.monthKey,
        );
        await _recalculateSettlementChain(
          serviceId: payment.serviceId,
          fromMonthKey: payment.monthKey,
        );
      });
    });
    _scheduleSync();
  }

  @override
  Future<void> deletePayment(PaymentTransaction payment) async {
    await _runForService(payment.serviceId, () async {
      await _database.transaction(() async {
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
        await _reallocatePayments(
          serviceId: payment.serviceId,
          monthKey: payment.monthKey,
        );
        await _recalculateSettlementChain(
          serviceId: payment.serviceId,
          fromMonthKey: payment.monthKey,
        );
      });
    });
    _scheduleSync();
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
  Future<PaymentSettlementPreview> getPaymentSettlementPreview({
    required String serviceId,
    required String monthKey,
    required int paymentCents,
  }) async {
    await _recalculateSettlement(serviceId: serviceId, monthKey: monthKey);
    final rows =
        await (_database.select(_database.monthlySettlementRecords)
              ..where(
                (table) =>
                    table.serviceId.equals(serviceId) &
                    table.monthKey.isSmallerOrEqualValue(monthKey) &
                    table.isDeleted.equals(false),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.monthKey)]))
            .get();

    final dueMonths = <PaymentMonthAllocation>[];
    var previousCumulativeRemaining = 0;
    for (final row in rows) {
      final effective = await _applyFollowingMonthPayments(row.toDomain());
      final ownOutstanding =
          (effective.remainingAmountCents - previousCumulativeRemaining).clamp(
            0,
            effective.remainingAmountCents,
          );
      previousCumulativeRemaining = effective.remainingAmountCents;
      if (ownOutstanding > 0) {
        dueMonths.add(
          PaymentMonthAllocation(
            monthKey: row.monthKey,
            dueBeforePaymentCents: ownOutstanding,
            allocatedCents: 0,
          ),
        );
      }
    }
    return _paymentAllocationCalculator.previewOldestFirst(
      paymentCents: paymentCents,
      dueMonths: dueMonths,
    );
  }

  @override
  Future<MonthlySettlement> getSettlement({
    required String serviceId,
    required String monthKey,
  }) async {
    final settlement = await _recalculateSettlement(
      serviceId: serviceId,
      monthKey: monthKey,
    );
    return _applyFollowingMonthPayments(settlement);
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
    final calculatedSettlement = await _recalculateSettlement(
      serviceId: serviceId,
      monthKey: monthKey,
      service: service,
      advances: advances,
      baseGrossAmountCents: baseBill.grossAmountCents,
    );
    final settlement = await _applyFollowingMonthPayments(calculatedSettlement);
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
  Future<void> syncPending() {
    if (!_syncService.isConfigured) {
      return Future.value();
    }
    return _syncCoordinator.syncPending();
  }

  @override
  Future<void> syncUserDataAndClearLocal({required String userId}) async {
    if (!_syncService.isConfigured) {
      throw StateError('Supabase is not configured for remote sync.');
    }
    if (_syncService.isLocalDevelopmentUser(userId)) {
      throw StateError('Sign in with Supabase before syncing local data.');
    }

    await _syncCoordinator.ensureRemoteSchemaVersion();
    await _syncService.transferUserDataAndClearLocal(userId);
  }

  @override
  Future<void> syncRemoteChanges({
    required String userId,
    required String monthKey,
  }) async {
    if (!_syncService.isConfigured ||
        _syncService.isLocalDevelopmentUser(userId)) {
      return;
    }
    await _syncCoordinator.ensureRemoteSchemaVersion();
    await _syncService.pullMonth(userId: userId, monthKey: monthKey);
    await syncPending();
    await _syncService.markMonthCached(userId: userId, monthKey: monthKey);
  }

  @override
  Future<bool> isMonthCached({
    required String userId,
    required String monthKey,
  }) {
    return _syncService.isMonthCached(userId: userId, monthKey: monthKey);
  }

  @override
  Future<void> hydrateMonth({
    required String userId,
    required String monthKey,
    bool forceRefresh = false,
  }) async {
    if (!_syncService.isConfigured ||
        _syncService.isLocalDevelopmentUser(userId)) {
      return;
    }
    await _syncCoordinator.hydrateMonth(
      userId: userId,
      monthKey: monthKey,
      forceRefresh: forceRefresh,
      isCached: isMonthCached,
      pullMonth: _pullAndPushMonth,
    );
  }

  Future<void> _pullAndPushMonth({
    required String userId,
    required String monthKey,
  }) async {
    await _syncService.pullMonth(userId: userId, monthKey: monthKey);
    await syncPending();
    await _syncService.markMonthCached(userId: userId, monthKey: monthKey);
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
    final previousSettlement =
        _serviceStartDateResolver.canUsePreviousSettlement(
          service: activeService,
          selectedMonthKey: monthKey,
        )
        ? await _loadSettlement(
            serviceId: serviceId,
            monthKey: _previousMonthKey(monthKey),
          )
        : null;
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

  Future<void> _recalculateSettlementChain({
    required String serviceId,
    required String fromMonthKey,
  }) async {
    final monthKeys = <String>{fromMonthKey};
    final settlementRows =
        await (_database.select(_database.monthlySettlementRecords)..where(
              (table) =>
                  table.serviceId.equals(serviceId) &
                  table.monthKey.isBiggerOrEqualValue(fromMonthKey) &
                  table.isDeleted.equals(false),
            ))
            .get();
    monthKeys.addAll(settlementRows.map((row) => row.monthKey));
    final paymentRows =
        await (_database.select(_database.paymentTransactionRecords)..where(
              (table) =>
                  table.serviceId.equals(serviceId) &
                  table.monthKey.isBiggerOrEqualValue(fromMonthKey),
            ))
            .get();
    monthKeys.addAll(paymentRows.map((row) => row.monthKey));

    final sortedMonthKeys = monthKeys.toList()..sort();
    for (final monthKey in sortedMonthKeys) {
      await _reallocatePayments(serviceId: serviceId, monthKey: monthKey);
      await _recalculateSettlement(serviceId: serviceId, monthKey: monthKey);
    }
  }

  Future<void> _reallocatePayments({
    required String serviceId,
    required String monthKey,
  }) async {
    final service = await _loadService(serviceId, monthKey);
    final advances = await getAdvances(
      serviceId: serviceId,
      monthKey: monthKey,
    );
    final gross = _billCalculator
        .calculate(service: service, advances: advances)
        .grossAmountCents;
    final previousSettlement =
        _serviceStartDateResolver.canUsePreviousSettlement(
          service: service,
          selectedMonthKey: monthKey,
        )
        ? await _loadSettlement(
            serviceId: serviceId,
            monthKey: _previousMonthKey(monthKey),
          )
        : null;
    final openingPending =
        previousSettlement?.carryForwardToNextMonthCents ?? 0;
    final openingAdvance = previousSettlement?.advanceToNextMonthCents ?? 0;
    final manualAdvance = advances.fold<int>(
      0,
      (sum, advance) => sum + advance.amountCents,
    );
    final availableAdvance = openingAdvance + manualAdvance;
    final currentAdvanceUsed = availableAdvance.clamp(0, gross);
    final currentDue = gross - currentAdvanceUsed;
    final previousAdvanceUsed = (availableAdvance - currentAdvanceUsed).clamp(
      0,
      openingPending,
    );
    final previousDue = openingPending - previousAdvanceUsed;

    final rows =
        await (_database.select(_database.paymentTransactionRecords)
              ..where(
                (table) =>
                    table.serviceId.equals(serviceId) &
                    table.monthKey.equals(monthKey),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.paymentDate),
                (table) => OrderingTerm.asc(table.createdAt),
              ]))
            .get();
    var remainingPrevious = previousDue;
    var remainingCurrent = currentDue;
    final now = DateTime.now();
    for (final row in rows) {
      if (row.isDeleted) {
        await (_database.update(
          _database.paymentTransactionRecords,
        )..where((table) => table.id.equals(row.id))).write(
          PaymentTransactionRecordsCompanion(
            currentMonthAmountCents: const Value(0),
            previousBalanceAmountCents: const Value(0),
            advanceAmountCents: const Value(0),
            updatedAt: Value(now),
            pendingSync: const Value(true),
          ),
        );
        continue;
      }
      final allocation = _paymentAllocationCalculator.calculate(
        paymentCents: row.amountCents,
        currentMonthDueCents: remainingCurrent,
        previousBalanceCents: remainingPrevious,
      );
      remainingPrevious -= allocation.previousBalanceCents;
      remainingCurrent -= allocation.currentMonthCents;
      await (_database.update(
        _database.paymentTransactionRecords,
      )..where((table) => table.id.equals(row.id))).write(
        PaymentTransactionRecordsCompanion(
          currentMonthAmountCents: Value(allocation.currentMonthCents),
          previousBalanceAmountCents: Value(allocation.previousBalanceCents),
          advanceAmountCents: Value(allocation.advanceCents),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
    }
  }

  Future<MonthlySettlement> _applyFollowingMonthPayments(
    MonthlySettlement settlement,
  ) async {
    final rows =
        await (_database.select(_database.paymentTransactionRecords)..where(
              (table) =>
                  table.serviceId.equals(settlement.serviceId) &
                  table.monthKey.isBiggerThanValue(settlement.monthKey) &
                  table.isDeleted.equals(false),
            ))
            .get();
    final appliedToPrevious = rows.fold<int>(
      0,
      (sum, row) => sum + row.previousBalanceAmountCents,
    );
    if (appliedToPrevious == 0) {
      return settlement;
    }
    final applied = appliedToPrevious.clamp(0, settlement.remainingAmountCents);
    final remaining = settlement.remainingAmountCents - applied;
    return MonthlySettlement(
      id: settlement.id,
      userId: settlement.userId,
      serviceId: settlement.serviceId,
      monthKey: settlement.monthKey,
      grossAmountCents: settlement.grossAmountCents,
      advanceUsedCents: settlement.advanceUsedCents,
      previousCarryForwardCents: settlement.previousCarryForwardCents,
      previousAdvanceCents: settlement.previousAdvanceCents,
      payableAmountCents: settlement.payableAmountCents,
      paidAmountCents: settlement.paidAmountCents + applied,
      remainingAmountCents: remaining,
      carryForwardToNextMonthCents: remaining,
      advanceToNextMonthCents: settlement.advanceToNextMonthCents,
      status: remaining == 0
          ? SettlementStatus.paid
          : SettlementStatus.partiallyPaid,
      generatedAt: settlement.generatedAt,
      updatedAt: settlement.updatedAt,
      pendingSync: settlement.pendingSync,
    );
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

  Future<List<HouseholdService>> _loadServices({
    required String userId,
    required String monthKey,
  }) async {
    final rows =
        await (_database.select(_database.serviceRecords)..where(
              (table) =>
                  table.userId.equals(userId) & table.isDeleted.equals(false),
            ))
            .get();
    final visibleRows = <ServiceRecord>[];
    var repairedStartMonth = false;
    for (final row in rows) {
      final effectiveMonthKey = _effectiveServiceMonthKey(
        storedMonthKey: row.monthKey,
        description: row.description,
      );
      if (effectiveMonthKey.compareTo(monthKey) > 0) {
        continue;
      }
      if (effectiveMonthKey != row.monthKey) {
        await (_database.update(
          _database.serviceRecords,
        )..where((table) => table.id.equals(row.id))).write(
          ServiceRecordsCompanion(
            monthKey: Value(effectiveMonthKey),
            updatedAt: Value(DateTime.now()),
            pendingSync: const Value(true),
          ),
        );
        repairedStartMonth = true;
      }
      visibleRows.add(row);
    }
    if (repairedStartMonth) {
      _scheduleSync();
    }
    if (visibleRows.isEmpty) {
      return const [];
    }

    final serviceIds = visibleRows.map((row) => row.id).toSet();
    final entryRows =
        await (_database.select(_database.entryRecords)..where(
              (table) =>
                  table.serviceId.isIn(serviceIds) &
                  table.monthKey.equals(monthKey) &
                  table.isDeleted.equals(false),
            ))
            .get();
    final entriesByService = <String, List<ServiceEntry>>{};
    for (final row in entryRows) {
      entriesByService
          .putIfAbsent(row.serviceId, () => <ServiceEntry>[])
          .add(row.toDomain());
    }

    return visibleRows
        .map(
          (row) => row.toDomain(
            entriesByService[row.id] ?? const [],
            activeMonthKey: monthKey,
          ),
        )
        .toList();
  }

  void _scheduleSync() {
    if (_syncService.isConfigured) {
      _syncCoordinator.schedulePendingSync();
    }
  }

  Future<T> _runForService<T>(
    String serviceId,
    Future<T> Function() action,
  ) async {
    final previous = _entityOperationGates[serviceId];
    final gate = Completer<void>();
    final gateFuture = gate.future;
    _entityOperationGates[serviceId] = gateFuture;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {
        // A failed operation must not block later local writes.
      }
    }
    try {
      return await action();
    } finally {
      gate.complete();
      if (identical(_entityOperationGates[serviceId], gateFuture)) {
        _entityOperationGates.remove(serviceId);
      }
    }
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

  String _previousMonthKey(String key) {
    return LedgerMonth.parse(key).shift(-1).key;
  }
}

class _OverviewTotals {
  const _OverviewTotals({
    this.totalPayableCents = 0,
    this.advancePaidCents = 0,
  });

  final int totalPayableCents;
  final int advancePaidCents;
}
