import '../entities/advance_payment.dart';
import '../entities/household_service.dart';
import '../entities/ledger_overview.dart';
import '../entities/monthly_bill.dart';
import '../entities/monthly_settlement.dart';
import '../entities/payment_transaction.dart';
import '../entities/service_entry.dart';

abstract interface class LedgerRepository {
  Stream<LedgerOverview> watchOverview({
    required String userId,
    required String monthKey,
  });
  Future<LedgerOverview> getOverview({
    required String userId,
    required String monthKey,
  });
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
  });
  Future<HouseholdService> updateService({
    required String id,
    required String name,
    required String description,
    required String unit,
    required double defaultQuantity,
    required int rateCents,
    required int monthlyAmountCents,
  });
  Future<void> deleteService({
    required String serviceId,
    required String monthKey,
  });
  Future<void> saveEntry(ServiceEntry entry);
  Future<void> saveAdvance(AdvancePayment advance);
  Future<List<AdvancePayment>> getAdvances({
    required String serviceId,
    required String monthKey,
  });
  Future<void> savePayment(PaymentTransaction payment);
  Future<void> deletePayment(PaymentTransaction payment);
  Future<List<PaymentTransaction>> getPayments({
    required String serviceId,
    required String monthKey,
  });
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String serviceId,
  });
  Future<MonthlySettlement> getSettlement({
    required String serviceId,
    required String monthKey,
  });
  Future<MonthlyBill> getMonthlyBill({
    required String serviceId,
    required String monthKey,
  });
  Future<void> syncRemoteChanges({
    required String userId,
    required String monthKey,
  });
  Future<void> syncPending();
  Future<void> syncUserDataAndClearLocal({required String userId});
  Future<String?> getLocalPreference(String key);
  Future<void> saveLocalPreference({
    required String key,
    required String value,
  });
}
