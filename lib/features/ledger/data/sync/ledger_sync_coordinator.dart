import 'dart:async';

typedef MonthCacheLookup =
    Future<bool> Function({required String userId, required String monthKey});
typedef MonthPull =
    Future<void> Function({required String userId, required String monthKey});

class LedgerSyncCoordinator {
  LedgerSyncCoordinator({
    required int requiredSchemaVersion,
    required Future<int?> Function() fetchSchemaVersion,
    required Future<void> Function() performPendingSync,
  }) : this._(requiredSchemaVersion, fetchSchemaVersion, performPendingSync);

  LedgerSyncCoordinator._(
    this._requiredSchemaVersion,
    this._fetchSchemaVersion,
    this._performPendingSync,
  );

  final int _requiredSchemaVersion;
  final Future<int?> Function() _fetchSchemaVersion;
  final Future<void> Function() _performPendingSync;
  final Map<String, Future<void>> _monthHydrations = {};

  Future<void>? _syncFuture;
  Future<void>? _schemaValidationFuture;
  bool _syncAgain = false;

  Future<void> syncPending() async {
    final running = _syncFuture;
    if (running != null) {
      _syncAgain = true;
      return running;
    }
    _syncAgain = false;
    final sync = _runPendingSyncLoop();
    _syncFuture = sync;
    try {
      await sync;
    } finally {
      if (identical(_syncFuture, sync)) {
        _syncFuture = null;
      }
    }
  }

  void schedulePendingSync() {
    unawaited(syncPending().catchError((_) {}));
  }

  Future<void> hydrateMonth({
    required String userId,
    required String monthKey,
    required bool forceRefresh,
    required MonthCacheLookup isCached,
    required MonthPull pullMonth,
  }) async {
    if (!forceRefresh && await isCached(userId: userId, monthKey: monthKey)) {
      return;
    }
    final key = '$userId:$monthKey';
    final activeHydration = _monthHydrations[key];
    if (activeHydration != null) {
      return activeHydration;
    }
    final hydration = _hydrate(
      userId: userId,
      monthKey: monthKey,
      pullMonth: pullMonth,
    );
    _monthHydrations[key] = hydration;
    try {
      await hydration;
    } finally {
      if (identical(_monthHydrations[key], hydration)) {
        _monthHydrations.remove(key);
      }
    }
  }

  Future<void> ensureRemoteSchemaVersion() {
    final activeValidation = _schemaValidationFuture;
    if (activeValidation != null) {
      return activeValidation;
    }
    final validation = _validateRemoteSchemaVersion();
    _schemaValidationFuture = validation;
    return validation.catchError((Object error, StackTrace stackTrace) {
      if (identical(_schemaValidationFuture, validation)) {
        _schemaValidationFuture = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> _runPendingSyncLoop() async {
    await ensureRemoteSchemaVersion();
    while (true) {
      final replayRequestedBeforeRun = _syncAgain;
      _syncAgain = false;
      await _performPendingSync();
      if (!replayRequestedBeforeRun && !_syncAgain) {
        return;
      }
    }
  }

  Future<void> _hydrate({
    required String userId,
    required String monthKey,
    required MonthPull pullMonth,
  }) async {
    await ensureRemoteSchemaVersion();
    await pullMonth(userId: userId, monthKey: monthKey);
  }

  Future<void> _validateRemoteSchemaVersion() async {
    final version = await _fetchSchemaVersion();
    if (version == null || version < _requiredSchemaVersion) {
      throw StateError(
        'Supabase ledger schema is not ready. Apply the latest migration.',
      );
    }
  }
}
