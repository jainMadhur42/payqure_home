import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/sync/ledger_sync_coordinator.dart';

void main() {
  test('concurrent sync requests are serialized and replayed once', () async {
    final firstRun = Completer<void>();
    var runs = 0;
    var schemaReads = 0;
    final coordinator = LedgerSyncCoordinator(
      requiredSchemaVersion: 4,
      fetchSchemaVersion: () async {
        schemaReads++;
        return 4;
      },
      performPendingSync: () async {
        runs++;
        if (runs == 1) {
          await firstRun.future;
        }
      },
    );

    final first = coordinator.syncPending();
    final second = coordinator.syncPending();
    firstRun.complete();
    await Future.wait([first, second]);

    expect(runs, 2);
    expect(schemaReads, 1);
  });

  test('same month hydration is shared between callers', () async {
    final pullCompleter = Completer<void>();
    var pulls = 0;
    final coordinator = LedgerSyncCoordinator(
      requiredSchemaVersion: 4,
      fetchSchemaVersion: () async => 4,
      performPendingSync: () async {},
    );

    Future<void> pull({
      required String userId,
      required String monthKey,
    }) async {
      pulls++;
      await pullCompleter.future;
    }

    Future<bool> isCached({
      required String userId,
      required String monthKey,
    }) async {
      return false;
    }

    final first = coordinator.hydrateMonth(
      userId: 'user',
      monthKey: '2026-06',
      forceRefresh: false,
      isCached: isCached,
      pullMonth: pull,
    );
    final second = coordinator.hydrateMonth(
      userId: 'user',
      monthKey: '2026-06',
      forceRefresh: false,
      isCached: isCached,
      pullMonth: pull,
    );
    pullCompleter.complete();
    await Future.wait([first, second]);

    expect(pulls, 1);
  });

  test('schema mismatch prevents persistence work', () async {
    var syncRuns = 0;
    final coordinator = LedgerSyncCoordinator(
      requiredSchemaVersion: 4,
      fetchSchemaVersion: () async => 3,
      performPendingSync: () async {
        syncRuns++;
      },
    );

    await expectLater(coordinator.syncPending(), throwsStateError);

    expect(syncRuns, 0);
  });
}
