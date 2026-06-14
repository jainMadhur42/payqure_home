class ServiceMetadata {
  const ServiceMetadata({
    this.providerName = '',
    this.contactNumber = '',
    this.serviceTime = '',
    this.startDate,
    this.remindBeforeMinutes = 0,
    this.templateId = '',
  });

  final String providerName;
  final String contactNumber;
  final String serviceTime;
  final DateTime? startDate;
  final int remindBeforeMinutes;
  final String templateId;

  ServiceMetadata copyWith({
    String? providerName,
    String? contactNumber,
    String? serviceTime,
    DateTime? startDate,
    int? remindBeforeMinutes,
    String? templateId,
  }) {
    return ServiceMetadata(
      providerName: providerName ?? this.providerName,
      contactNumber: contactNumber ?? this.contactNumber,
      serviceTime: serviceTime ?? this.serviceTime,
      startDate: startDate ?? this.startDate,
      remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
      templateId: templateId ?? this.templateId,
    );
  }

  factory ServiceMetadata.parse(String description) {
    final fields = <String, String>{};
    for (final item in description.split(' • ')) {
      final separator = item.indexOf(':');
      if (separator < 0) {
        continue;
      }
      fields[item.substring(0, separator).trim().toLowerCase()] = item
          .substring(separator + 1)
          .trim();
    }
    return ServiceMetadata(
      providerName: fields['provider'] ?? '',
      contactNumber: fields['contact'] ?? '',
      serviceTime: fields['service time'] ?? '',
      startDate: _parseDate(fields['start date']),
      remindBeforeMinutes: _parseReminderMinutes(fields['reminder']) ?? 0,
      templateId: fields['template'] ?? '',
    );
  }

  String encode() {
    final date = startDate;
    return [
      'Provider: $providerName',
      'Contact: $contactNumber',
      if (serviceTime.trim().isNotEmpty) 'Service time: $serviceTime',
      if (date != null)
        'Start date: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      if (remindBeforeMinutes > 0)
        'Reminder: $remindBeforeMinutes minutes before',
      if (templateId.trim().isNotEmpty) 'Template: $templateId',
    ].join(' • ');
  }

  String? valueFor(String field) {
    return switch (field.trim().toLowerCase()) {
      'provider' => providerName,
      'contact' => contactNumber,
      'service time' => serviceTime,
      'start date' when startDate != null =>
        '${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}',
      'reminder' when remindBeforeMinutes > 0 =>
        '$remindBeforeMinutes minutes before',
      'template' => templateId,
      _ => null,
    };
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }
    final parts = value.split('/');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static int? _parseReminderMinutes(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.split(' ').first);
  }
}
