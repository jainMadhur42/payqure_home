class AdvancePayment {
  const AdvancePayment({
    required this.id,
    required this.serviceId,
    required this.monthKey,
    required this.amountCents,
    required this.paidOn,
    this.note = '',
    this.pendingSync = false,
  });

  final String id;
  final String serviceId;
  final String monthKey;
  final int amountCents;
  final DateTime paidOn;
  final String note;
  final bool pendingSync;

  AdvancePayment copyWith({
    int? amountCents,
    DateTime? paidOn,
    String? note,
    bool? pendingSync,
  }) {
    return AdvancePayment(
      id: id,
      serviceId: serviceId,
      monthKey: monthKey,
      amountCents: amountCents ?? this.amountCents,
      paidOn: paidOn ?? this.paidOn,
      note: note ?? this.note,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
