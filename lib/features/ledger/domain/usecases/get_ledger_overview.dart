import '../entities/ledger_overview.dart';
import '../repositories/ledger_repository.dart';

class GetLedgerOverview {
  const GetLedgerOverview(this._repository);

  final LedgerRepository _repository;

  Future<LedgerOverview> call({
    required String userId,
    required String monthKey,
  }) {
    return _repository.getOverview(userId: userId, monthKey: monthKey);
  }
}
