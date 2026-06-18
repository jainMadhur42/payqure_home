import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/advance_payment.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/payment_settlement_preview.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/history_sorter.dart';

class PaymentOperationsController {
  const PaymentOperationsController(this._repository);

  final LedgerRepository _repository;

  Future<void> saveAdvance({
    required HouseholdService service,
    required String monthKey,
    required int amountCents,
    required DateTime paidOn,
    required String note,
  }) {
    return _repository.saveAdvance(
      AdvancePayment(
        id: IdGenerator.create('advance'),
        serviceId: service.id,
        monthKey: monthKey,
        amountCents: amountCents,
        paidOn: paidOn,
        note: note,
      ),
    );
  }

  Future<void> updateAdvance({
    required AdvancePayment advance,
    required int amountCents,
    required DateTime paidOn,
    required String note,
  }) {
    return _repository.saveAdvance(
      advance.copyWith(
        amountCents: amountCents,
        paidOn: paidOn,
        note: note,
        pendingSync: true,
      ),
    );
  }

  Future<void> deleteAdvance(AdvancePayment advance) {
    return _repository.deleteAdvance(advance);
  }

  Future<void> savePayment({
    required String userId,
    required HouseholdService service,
    required String monthKey,
    required int amountCents,
    required DateTime paymentDate,
    required PaymentMode mode,
    required String note,
  }) {
    return _repository.savePayment(
      PaymentTransaction(
        id: IdGenerator.create('payment'),
        userId: userId,
        serviceId: service.id,
        monthKey: monthKey,
        amountCents: amountCents,
        paymentDate: paymentDate,
        mode: mode,
        note: note,
        updatedAt: DateTime.now(),
        pendingSync: true,
      ),
    );
  }

  Future<void> updatePayment({
    required PaymentTransaction payment,
    required int amountCents,
    required DateTime paymentDate,
    required PaymentMode mode,
    required String note,
  }) {
    return _repository.savePayment(
      payment.copyWith(
        amountCents: amountCents,
        paymentDate: paymentDate,
        mode: mode,
        note: note,
        pendingSync: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deletePayment(PaymentTransaction payment) {
    return _repository.deletePayment(payment);
  }

  Future<List<PaymentTransaction>> paymentHistory(String serviceId) {
    return _repository.getPaymentHistory(serviceId: serviceId);
  }

  Future<PaymentSettlementPreview> settlementPreview({
    required HouseholdService service,
    required String monthKey,
    required int paymentCents,
  }) {
    return _repository.getPaymentSettlementPreview(
      serviceId: service.id,
      monthKey: monthKey,
      paymentCents: paymentCents,
    );
  }

  Future<List<ServiceHistoryItem>> globalPaymentHistory(
    List<HouseholdService> services,
  ) async {
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day + 1);
    final serviceItems = await Future.wait(
      services.map((service) async {
        final payments = await paymentHistory(service.id);
        return payments
            .where((payment) => payment.paymentDate.isBefore(endOfToday))
            .map(
              (payment) => ServiceHistoryItem(
                id: payment.id,
                service: service,
                type: ServiceHistoryType.payment,
                amountCents: payment.amountCents,
                date: payment.paymentDate,
                modeLabel: payment.mode.label,
                note: payment.note,
                pendingSync: payment.pendingSync,
                payment: payment,
              ),
            )
            .toList();
      }),
    );
    return HistorySorter.itemsNewestFirst(
      serviceItems.expand((items) => items),
    );
  }

  Future<List<ServiceHistoryItem>> globalAdvanceHistory(
    List<HouseholdService> services,
  ) async {
    final serviceItems = await Future.wait(services.map(serviceAdvanceHistory));
    return HistorySorter.itemsNewestFirst(
      serviceItems.expand((items) => items),
    );
  }

  Future<List<ServiceHistoryItem>> serviceAdvanceHistory(
    HouseholdService service,
  ) async {
    final advances = await _repository.getAdvanceHistory(serviceId: service.id);
    return HistorySorter.itemsNewestFirst(
      advances.map(
        (advance) => ServiceHistoryItem(
          id: advance.id,
          service: service,
          type: ServiceHistoryType.advance,
          amountCents: advance.amountCents,
          date: advance.paidOn,
          modeLabel: 'Advance',
          note: advance.note,
          pendingSync: advance.pendingSync,
          advance: advance,
        ),
      ),
    );
  }
}
