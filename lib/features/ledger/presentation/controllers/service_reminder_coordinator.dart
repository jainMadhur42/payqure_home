import 'dart:async';

import '../../data/services/local_notification_service.dart';
import '../../domain/entities/household_service.dart';

class ServiceReminderCoordinator {
  ServiceReminderCoordinator(this._scheduler);

  final ServiceReminderScheduler _scheduler;
  Future<void> _configurationTail = Future<void>.value();
  String _scheduledSignature = '';
  bool _permissionRequested = false;

  Future<void> configure(
    List<HouseholdService> services, {
    required bool requestPermission,
    bool force = false,
  }) {
    final operation = _configurationTail.then(
      (_) => _configure(
        services,
        requestPermission: requestPermission,
        force: force,
      ),
    );
    _configurationTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> reset() async {
    await _configurationTail;
    await _scheduler.cancelServiceReminders();
    _scheduledSignature = '';
    _permissionRequested = false;
  }

  Future<void> _configure(
    List<HouseholdService> services, {
    required bool requestPermission,
    required bool force,
  }) async {
    final signature = _signatureFor(services);
    if (!force && signature == _scheduledSignature) {
      return;
    }

    var enabled = await _scheduler.notificationsEnabled();
    if (!enabled && requestPermission && !_permissionRequested) {
      _permissionRequested = true;
      enabled = await _scheduler.requestPermission();
    }
    if (!enabled) {
      return;
    }

    await _scheduler.scheduleServices(services);
    _scheduledSignature = signature;
  }

  String _signatureFor(List<HouseholdService> services) {
    final sorted = [...services]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map(
          (service) => [
            service.id,
            service.name,
            service.description,
            service.updatedAt.toUtc().toIso8601String(),
          ].join(':'),
        )
        .join('|');
  }
}
