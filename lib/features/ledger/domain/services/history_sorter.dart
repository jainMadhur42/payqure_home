import '../entities/payment_transaction.dart';
import '../entities/service_history_item.dart';

abstract final class HistorySorter {
  static List<PaymentTransaction> paymentsNewestFirst(
    Iterable<PaymentTransaction> payments,
  ) {
    return [...payments]..sort((left, right) {
      final dateComparison = right.paymentDate.compareTo(left.paymentDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      final updatedComparison = right.updatedAt.compareTo(left.updatedAt);
      if (updatedComparison != 0) {
        return updatedComparison;
      }
      return right.id.compareTo(left.id);
    });
  }

  static List<ServiceHistoryItem> itemsNewestFirst(
    Iterable<ServiceHistoryItem> items,
  ) {
    return [...items]..sort((left, right) {
      final dateComparison = right.date.compareTo(left.date);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return right.id.compareTo(left.id);
    });
  }
}
