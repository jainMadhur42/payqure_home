import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/services/local_notification_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/service_reminder_coordinator.dart';

void main() {
  test(
    'restores schedules without prompting when permission already exists',
    () async {
      final scheduler = _FakeReminderScheduler(enabled: true);
      final coordinator = ServiceReminderCoordinator(scheduler);

      await coordinator.configure([_service()], requestPermission: false);

      expect(scheduler.permissionRequests, 0);
      expect(scheduler.scheduledServices.single.id, 'service');
    },
  );

  test('prompts once and schedules after permission is granted', () async {
    final scheduler = _FakeReminderScheduler(
      enabled: false,
      grantPermission: true,
    );
    final coordinator = ServiceReminderCoordinator(scheduler);

    await coordinator.configure([_service()], requestPermission: true);
    await coordinator.configure([_service()], requestPermission: true);

    expect(scheduler.permissionRequests, 1);
    expect(scheduler.scheduleCalls, 1);
  });

  test(
    'force reconciliation restores a schedule with unchanged services',
    () async {
      final scheduler = _FakeReminderScheduler(enabled: true);
      final coordinator = ServiceReminderCoordinator(scheduler);
      final services = [_service()];

      await coordinator.configure(services, requestPermission: false);
      await coordinator.configure(
        services,
        requestPermission: false,
        force: true,
      );

      expect(scheduler.scheduleCalls, 2);
    },
  );
}

class _FakeReminderScheduler implements ServiceReminderScheduler {
  _FakeReminderScheduler({required this.enabled, this.grantPermission = false});

  bool enabled;
  final bool grantPermission;
  int permissionRequests = 0;
  int scheduleCalls = 0;
  List<HouseholdService> scheduledServices = const [];

  @override
  Stream<String> get serviceReminderTaps => const Stream.empty();

  @override
  Future<void> cancelServiceReminders() async {}

  @override
  Future<String?> consumeLaunchServiceId() async => null;

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = grantPermission;
    return enabled;
  }

  @override
  Future<void> scheduleServices(List<HouseholdService> services) async {
    scheduleCalls++;
    scheduledServices = List.unmodifiable(services);
  }
}

HouseholdService _service() {
  return HouseholdService(
    id: 'service',
    userId: 'user',
    name: 'Milkman',
    description:
        'Time: 8:00 AM • Reminder: 15 minutes before • Start date: 01/06/2026',
    icon: 'milkman',
    templateType: ServiceTemplateType.quantity,
    monthKey: '2026-06',
    unit: 'L',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: const [],
    updatedAt: DateTime(2026, 6, 1),
  );
}
