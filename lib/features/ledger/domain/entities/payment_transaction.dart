enum PaymentMode { cash, upi, other }

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.monthKey,
    required this.amountCents,
    required this.paymentDate,
    required this.mode,
    required this.updatedAt,
    this.note = '',
    this.currentMonthAmountCents = 0,
    this.previousBalanceAmountCents = 0,
    this.advanceAmountCents = 0,
    this.pendingSync = false,
    this.isDeleted = false,
  });

  final String id;
  final String userId;
  final String serviceId;
  final String monthKey;
  final int amountCents;
  final DateTime paymentDate;
  final PaymentMode mode;
  final String note;
  final int currentMonthAmountCents;
  final int previousBalanceAmountCents;
  final int advanceAmountCents;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;

  PaymentTransaction copyWith({
    int? amountCents,
    DateTime? paymentDate,
    PaymentMode? mode,
    String? note,
    int? currentMonthAmountCents,
    int? previousBalanceAmountCents,
    int? advanceAmountCents,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) {
    return PaymentTransaction(
      id: id,
      userId: userId,
      serviceId: serviceId,
      monthKey: monthKey,
      amountCents: amountCents ?? this.amountCents,
      paymentDate: paymentDate ?? this.paymentDate,
      mode: mode ?? this.mode,
      note: note ?? this.note,
      currentMonthAmountCents:
          currentMonthAmountCents ?? this.currentMonthAmountCents,
      previousBalanceAmountCents:
          previousBalanceAmountCents ?? this.previousBalanceAmountCents,
      advanceAmountCents: advanceAmountCents ?? this.advanceAmountCents,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

extension PaymentModeLabel on PaymentMode {
  String get dbValue {
    return switch (this) {
      PaymentMode.cash => 'cash',
      PaymentMode.upi => 'upi',
      PaymentMode.other => 'other',
    };
  }

  String get label {
    return switch (this) {
      PaymentMode.cash => 'Cash',
      PaymentMode.upi => 'UPI',
      PaymentMode.other => 'Other',
    };
  }
}
