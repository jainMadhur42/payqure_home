import 'dart:async';

import '../../domain/entities/ledger_overview.dart';
import '../../domain/repositories/ledger_repository.dart';

typedef OverviewChanged = void Function(LedgerOverview overview);

class MonthDataController {
  MonthDataController(this._repository);

  final LedgerRepository _repository;
  StreamSubscription<LedgerOverview>? _overviewSubscription;
  int _ledgerGeneration = 0;
  int _monthGeneration = 0;
  bool _disposed = false;

  Future<void> start({
    required String userId,
    required String monthKey,
    required OverviewChanged onOverview,
  }) async {
    final generation = ++_ledgerGeneration;
    await _overviewSubscription?.cancel();
    _overviewSubscription = _repository
        .watchOverview(userId: userId, monthKey: monthKey)
        .listen((overview) {
          if (_isCurrentLedger(generation, monthKey, overview.monthKey)) {
            onOverview(overview);
          }
        });

    final overview = await _repository.getOverview(
      userId: userId,
      monthKey: monthKey,
    );
    if (_isCurrentLedger(generation, monthKey, overview.monthKey)) {
      onOverview(overview);
    }
  }

  Future<bool> switchMonth({
    required String userId,
    required String monthKey,
    required void Function() onActivated,
    required OverviewChanged onOverview,
  }) async {
    final generation = ++_monthGeneration;
    await hydrate(userId: userId, monthKey: monthKey);
    if (!_isCurrentMonth(generation)) {
      return false;
    }
    onActivated();
    await start(userId: userId, monthKey: monthKey, onOverview: onOverview);
    return _isCurrentMonth(generation);
  }

  Future<void> hydrate({
    required String userId,
    required String monthKey,
    bool forceRefresh = false,
    bool useCacheOnFailure = false,
  }) async {
    try {
      await _repository
          .hydrateMonth(
            userId: userId,
            monthKey: monthKey,
            forceRefresh: forceRefresh,
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (useCacheOnFailure &&
          await _repository.isMonthCached(userId: userId, monthKey: monthKey)) {
        return;
      }
      rethrow;
    }
  }

  Future<LedgerOverview?> refresh({
    required String userId,
    required String monthKey,
  }) async {
    final generation = _ledgerGeneration;
    final overview = await _repository.getOverview(
      userId: userId,
      monthKey: monthKey,
    );
    if (!_isCurrentLedger(generation, monthKey, overview.monthKey)) {
      return null;
    }
    return overview;
  }

  bool _isCurrentLedger(
    int generation,
    String requestedMonth,
    String overviewMonth,
  ) {
    return !_disposed &&
        generation == _ledgerGeneration &&
        requestedMonth == overviewMonth;
  }

  bool _isCurrentMonth(int generation) {
    return !_disposed && generation == _monthGeneration;
  }

  Future<void> cancel() async {
    _ledgerGeneration++;
    _monthGeneration++;
    await _overviewSubscription?.cancel();
    _overviewSubscription = null;
  }

  void dispose() {
    _disposed = true;
    unawaited(cancel());
  }
}
