import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_metadata.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/services/service_reminder_planner.dart';

void main() {
  const planner = ServiceReminderPlanner();

  test('plans reminder before 12-hour service time', () {
    final plan = planner.planFor(
      service(
        metadata: const ServiceMetadata(
          serviceTime: '8:30 AM',
          remindBeforeMinutes: 15,
        ),
      ),
      now: DateTime(2026, 6, 7),
    );

    expect(plan, isNotNull);
    expect(plan!.hour, 8);
    expect(plan.minute, 15);
  });

  test(
    'wraps reminder to previous day time when reminder crosses midnight',
    () {
      final plan = planner.planFor(
        service(
          metadata: const ServiceMetadata(
            serviceTime: '00:10',
            remindBeforeMinutes: 30,
          ),
        ),
        now: DateTime(2026, 6, 7),
      );

      expect(plan, isNotNull);
      expect(plan!.hour, 23);
      expect(plan.minute, 40);
    },
  );

  test('skips services without reminder or before service start date', () {
    final plans = planner.plansFor([
      service(metadata: const ServiceMetadata(serviceTime: '09:00')),
      service(
        metadata: ServiceMetadata(
          serviceTime: '09:00',
          remindBeforeMinutes: 10,
          startDate: DateTime(2026, 6, 8),
        ),
      ),
    ], now: DateTime(2026, 6, 7));

    expect(plans, isEmpty);
  });

  test('schedule updates preserve unrelated service metadata', () {
    final original = ServiceMetadata(
      providerName: 'Ramesh',
      contactNumber: '9876543210',
      serviceTime: '8:30 AM',
      startDate: DateTime(2026, 6, 1),
      remindBeforeMinutes: 15,
      templateId: 'milkman',
    );

    final updated = original.copyWith(
      serviceTime: '9:00 AM',
      remindBeforeMinutes: 30,
    );
    final decoded = ServiceMetadata.parse(updated.encode());

    expect(decoded.providerName, 'Ramesh');
    expect(decoded.contactNumber, '9876543210');
    expect(decoded.startDate, DateTime(2026, 6, 1));
    expect(decoded.templateId, 'milkman');
    expect(decoded.serviceTime, '9:00 AM');
    expect(decoded.remindBeforeMinutes, 30);
  });
}

HouseholdService service({required ServiceMetadata metadata}) {
  return HouseholdService(
    id: 'service-${metadata.serviceTime}-${metadata.remindBeforeMinutes}',
    userId: 'user',
    name: 'Milkman',
    description: metadata.encode(),
    icon: 'milkman',
    templateType: ServiceTemplateType.quantity,
    monthKey: '2026-06',
    unit: 'L',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: const [],
    updatedAt: DateTime(2026, 6, 7),
  );
}
