import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/household_service.dart';
import '../../domain/services/service_reminder_planner.dart';

abstract interface class ServiceReminderScheduler {
  Stream<String> get serviceReminderTaps;
  Future<String?> consumeLaunchServiceId();
  Future<bool> notificationsEnabled();
  Future<bool> requestPermission();
  Future<void> scheduleServices(List<HouseholdService> services);
  Future<void> cancelServiceReminders();
}

class NoopServiceReminderScheduler implements ServiceReminderScheduler {
  const NoopServiceReminderScheduler();

  @override
  Stream<String> get serviceReminderTaps => const Stream.empty();

  @override
  Future<String?> consumeLaunchServiceId() async => null;

  @override
  Future<void> cancelServiceReminders() async {}

  @override
  Future<bool> notificationsEnabled() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleServices(List<HouseholdService> services) async {}
}

class LocalNotificationService implements ServiceReminderScheduler {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    ServiceReminderPlanner? planner,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _planner = planner ?? const ServiceReminderPlanner();

  static const _channelId = 'service_reminders';
  static const _payloadPrefix = 'service-reminder:';
  @visibleForTesting
  static const androidSmallIcon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;
  final ServiceReminderPlanner _planner;
  final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  Future<void>? _initialization;
  bool _launchPayloadConsumed = false;

  @override
  Stream<String> get serviceReminderTaps => _tapController.stream;

  Future<void> _initialize() {
    return _initialization ??= _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // The timezone package defaults to UTC if the platform cannot resolve it.
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(androidSmallIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );
  }

  @override
  Future<String?> consumeLaunchServiceId() async {
    if (_launchPayloadConsumed) {
      return null;
    }
    await _initialize();
    _launchPayloadConsumed = true;
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (!(launchDetails?.didNotificationLaunchApp ?? false)) {
      return null;
    }
    return _serviceIdFromPayload(launchDetails?.notificationResponse?.payload);
  }

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await android?.requestNotificationsPermission() ?? false,
      TargetPlatform.iOS =>
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
            false,
      _ => false,
    };
  }

  @override
  Future<bool> notificationsEnabled() async {
    await _initialize();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.areNotificationsEnabled() ??
            false,
      TargetPlatform.iOS =>
        (await _plugin
                    .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin
                    >()
                    ?.checkPermissions())
                ?.isEnabled ??
            false,
      _ => false,
    };
  }

  @override
  Future<void> scheduleServices(List<HouseholdService> services) async {
    await _initialize();
    await cancelServiceReminders();
    for (final plan in _planner.plansFor(services)) {
      final scheduledDate = _nextOccurrence(plan.hour, plan.minute);
      await _plugin.zonedSchedule(
        plan.notificationId,
        plan.serviceName,
        '${plan.serviceName} is scheduled at ${plan.serviceTimeLabel}.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Service reminders',
            channelDescription: 'Reminders before household service times',
            icon: androidSmallIcon,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$_payloadPrefix${plan.serviceId}',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  @override
  Future<void> cancelServiceReminders() async {
    await _initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(_payloadPrefix) ?? false) {
        await _plugin.cancel(request.id);
      }
    }
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final serviceId = _serviceIdFromPayload(response.payload);
    if (serviceId != null) {
      _tapController.add(serviceId);
    }
  }

  static String? _serviceIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) {
      return null;
    }
    final serviceId = payload.substring(_payloadPrefix.length).trim();
    return serviceId.isEmpty ? null : serviceId;
  }
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  // The foreground isolate handles routing once the app is resumed/launched.
}
