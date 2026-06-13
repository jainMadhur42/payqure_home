import 'advance_payment.dart';
import 'household_service.dart';
import 'payment_transaction.dart';

enum ServiceHistoryType { payment, advance }

class ServiceHistoryItem {
  const ServiceHistoryItem({
    required this.id,
    required this.service,
    required this.type,
    required this.amountCents,
    required this.date,
    required this.modeLabel,
    required this.note,
    required this.pendingSync,
    this.payment,
    this.advance,
  });

  final String id;
  final HouseholdService service;
  final ServiceHistoryType type;
  final int amountCents;
  final DateTime date;
  final String modeLabel;
  final String note;
  final bool pendingSync;
  final PaymentTransaction? payment;
  final AdvancePayment? advance;
}
