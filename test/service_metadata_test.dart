import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_metadata.dart';

void main() {
  test('service metadata preserves the existing description wire format', () {
    final metadata = ServiceMetadata(
      providerName: 'Ramesh',
      contactNumber: '9999999999',
      serviceTime: '08:30',
      startDate: DateTime(2026, 5, 25),
      remindBeforeMinutes: 15,
      templateId: 'milkman',
    );

    final decoded = ServiceMetadata.parse(metadata.encode());

    expect(decoded.providerName, 'Ramesh');
    expect(decoded.contactNumber, '9999999999');
    expect(decoded.serviceTime, '08:30');
    expect(decoded.startDate, DateTime(2026, 5, 25));
    expect(decoded.remindBeforeMinutes, 15);
    expect(decoded.templateId, 'milkman');
  });

  test('service metadata ignores malformed dates safely', () {
    final metadata = ServiceMetadata.parse(
      'Provider: Ramesh • Start date: 31/02/2026 • Template: milkman',
    );

    expect(metadata.providerName, 'Ramesh');
    expect(metadata.startDate, isNull);
    expect(metadata.templateId, 'milkman');
  });
}
