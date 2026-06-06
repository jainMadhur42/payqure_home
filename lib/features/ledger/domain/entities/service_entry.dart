enum ServiceEntryStatus {
  delivered,
  notDelivered,
  rateChanged,
  noEntry,
  halfDay,
}

class ServiceEntry {
  const ServiceEntry({
    required this.id,
    required this.serviceId,
    required this.day,
    required this.monthKey,
    required this.status,
    required this.quantity,
    required this.unit,
    required this.rateCents,
    required this.amountCents,
    required this.updatedAt,
    this.note = '',
    this.pendingSync = false,
  });

  final String id;
  final String serviceId;
  final int day;
  final String monthKey;
  final ServiceEntryStatus status;
  final double quantity;
  final String unit;
  final int rateCents;
  final int amountCents;
  final String note;
  final bool pendingSync;
  final DateTime updatedAt;

  String get quantityLabel {
    return switch (status) {
      ServiceEntryStatus.notDelivered => '0',
      ServiceEntryStatus.noEntry => '-',
      ServiceEntryStatus.halfDay => 'HD',
      _ when unit.isEmpty => quantity.toStringAsFixed(
        quantity.truncateToDouble() == quantity ? 0 : 1,
      ),
      _ =>
        '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)}$unit',
    };
  }

  ServiceEntry copyWith({
    ServiceEntryStatus? status,
    double? quantity,
    String? unit,
    int? rateCents,
    int? amountCents,
    String? note,
    bool? pendingSync,
    DateTime? updatedAt,
  }) {
    return ServiceEntry(
      id: id,
      serviceId: serviceId,
      day: day,
      monthKey: monthKey,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rateCents: rateCents ?? this.rateCents,
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      pendingSync: pendingSync ?? this.pendingSync,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
