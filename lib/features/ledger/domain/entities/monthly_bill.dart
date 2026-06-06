import 'advance_payment.dart';
import 'household_service.dart';
import 'monthly_settlement.dart';
import 'payment_transaction.dart';

class BillLineItem {
  const BillLineItem({required this.label, required this.amountCents});

  final String label;
  final int amountCents;
}

class MonthlyBill {
  const MonthlyBill({
    required this.service,
    required this.monthKey,
    required this.totalQuantity,
    required this.grossAmountCents,
    required this.advanceAmountCents,
    required this.payableAmountCents,
    required this.lines,
    required this.advances,
    this.payments = const [],
    this.settlement,
  });

  final HouseholdService service;
  final String monthKey;
  final double totalQuantity;
  final int grossAmountCents;
  final int advanceAmountCents;
  final int payableAmountCents;
  final List<BillLineItem> lines;
  final List<AdvancePayment> advances;
  final List<PaymentTransaction> payments;
  final MonthlySettlement? settlement;
}
