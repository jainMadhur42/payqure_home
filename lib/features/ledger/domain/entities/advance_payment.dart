class AdvancePayment {
  const AdvancePayment({
    required this.id,
    required this.serviceId,
    required this.monthKey,
    required this.amountCents,
    required this.paidOn,
    this.note = '',
  });

  final String id;
  final String serviceId;
  final String monthKey;
  final int amountCents;
  final DateTime paidOn;
  final String note;
}
