import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class AnalyticsEvents {
  static const signUpStarted = 'sign_up_started';
  static const signUpCompleted = 'sign_up_completed';
  static const loginCompleted = 'login_completed';
  static const forgotPasswordStarted = 'forgot_password_started';
  static const forgotPasswordCompleted = 'forgot_password_completed';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingScreenViewed = 'onboarding_screen_viewed';
  static const onboardingSkipped = 'onboarding_skipped';
  static const onboardingCompleted = 'onboarding_completed';
  static const addServiceStarted = 'add_service_started';
  static const serviceTemplateSelected = 'service_template_selected';
  static const serviceCreated = 'service_created';
  static const serviceUpdated = 'service_updated';
  static const serviceDeleted = 'service_deleted';
  static const quickLogOpened = 'quick_log_opened';
  static const quickLogCompleted = 'quick_log_completed';
  static const entryCreated = 'entry_created';
  static const entryUpdated = 'entry_updated';
  static const entryDeleted = 'entry_deleted';
  static const calendarDateTapped = 'calendar_date_tapped';
  static const recordPaymentStarted = 'record_payment_started';
  static const paymentRecorded = 'payment_recorded';
  static const paymentUpdated = 'payment_updated';
  static const paymentDeleted = 'payment_deleted';
  static const paymentHistoryViewed = 'payment_history_viewed';
  static const advanceAdded = 'advance_added';
  static const pdfGenerateStarted = 'pdf_generate_started';
  static const pdfGenerated = 'pdf_generated';
  static const pdfGenerationFailed = 'pdf_generation_failed';
  static const pdfShared = 'pdf_shared';
  static const offlineModeDetected = 'offline_mode_detected';
  static const syncStarted = 'sync_started';
  static const syncCompleted = 'sync_completed';
  static const syncFailed = 'sync_failed';
  static const localChangePending = 'local_change_pending';
}

abstract final class AnalyticsParams {
  static const method = 'method';
  static const screenName = 'screen_name';
  static const screenIndex = 'screen_index';
  static const serviceType = 'service_type';
  static const templateType = 'template_type';
  static const unitType = 'unit_type';
  static const currencyCode = 'currency_code';
  static const countryCode = 'country_code';
  static const appLanguage = 'app_language';
  static const signupMethod = 'signup_method';
  static const appVersion = 'app_version';
  static const autoMarkEnabled = 'auto_mark_enabled';
  static const defaultQuantity = 'default_quantity';
  static const unitPrice = 'unit_price';
  static const unitPriceBucket = 'unit_price_bucket';
  static const dailyWage = 'daily_wage';
  static const dailyWageBucket = 'daily_wage_bucket';
  static const allowHalfDay = 'allow_half_day';
  static const monthlyAmount = 'monthly_amount';
  static const monthlyAmountBucket = 'monthly_amount_bucket';
  static const entryStatus = 'entry_status';
  static const entrySource = 'entry_source';
  static const isPastDate = 'is_past_date';
  static const quantityChanged = 'quantity_changed';
  static const rateChanged = 'rate_changed';
  static const quantity = 'quantity';
  static const entryAmountBucket = 'entry_amount_bucket';
  static const paymentMode = 'payment_mode';
  static const paymentResult = 'payment_result';
  static const source = 'source';
  static const amountBucket = 'amount_bucket';
  static const monthType = 'month_type';
  static const entityType = 'entity_type';
  static const errorType = 'error_type';
  static const pendingCount = 'pending_count';
  static const serviceCount = 'service_count';
  static const hasQuantityService = 'has_quantity_service';
  static const hasAttendanceService = 'has_attendance_service';
  static const hasFixedMonthlyService = 'has_fixed_monthly_service';
  static const syncEntityType = 'sync_entity_type';
}

abstract final class AmountAnalyticsHelper {
  static String getAmountBucket(num amount) {
    final normalized = amount.abs();
    if (normalized == 0) return '0';
    if (normalized <= 100) return '1_100';
    if (normalized <= 500) return '101_500';
    if (normalized <= 1000) return '501_1000';
    if (normalized <= 2500) return '1001_2500';
    if (normalized <= 5000) return '2501_5000';
    if (normalized <= 10000) return '5001_10000';
    return '10000_plus';
  }

  static String centsBucket(int cents) => getAmountBucket(cents / 100);
}

class AppAnalytics {
  AppAnalytics._({
    FirebaseAnalytics? analytics,
    this._crashlytics,
    bool enabled = true,
  }) : _analytics = analytics,
       _enabled = enabled && analytics != null;

  factory AppAnalytics.disabled() => AppAnalytics._(enabled: false);

  static Future<AppAnalytics> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final crashlytics = FirebaseCrashlytics.instance;
      FlutterError.onError = (details) {
        unawaited(crashlytics.recordFlutterFatalError(details));
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(crashlytics.recordError(error, stack, fatal: true));
        return true;
      };
      return AppAnalytics._(
        analytics: FirebaseAnalytics.instance,
        crashlytics: crashlytics,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase analytics disabled: $error');
        debugPrint('$stackTrace');
      }
      return AppAnalytics.disabled();
    }
  }

  final FirebaseAnalytics? _analytics;
  final FirebaseCrashlytics? _crashlytics;
  final bool _enabled;

  bool get isEnabled => _enabled;

  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    if (!_enabled) return;
    unawaited(
      _guard(
        () => _analytics!.logEvent(
          name: name,
          parameters: _sanitizeParameters(parameters),
        ),
      ),
    );
  }

  void setUserProperties(Map<String, Object?> properties) {
    if (!_enabled) return;
    for (final entry in _sanitizeParameters(properties).entries) {
      unawaited(
        _guard(
          () => _analytics!.setUserProperty(
            name: entry.key,
            value: entry.value.toString(),
          ),
        ),
      );
    }
  }

  void logScreenView(String screenName) {
    if (!_enabled) return;
    unawaited(
      _guard(
        () => _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenName,
        ),
      ),
    );
  }

  void logErrorContext(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> keys = const {},
  }) {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    unawaited(
      _guard(() async {
        for (final entry in _sanitizeParameters(keys).entries) {
          await crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
        await crashlytics.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: false,
        );
      }),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Analytics call ignored: $error');
      }
    }
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final result = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is bool || value is num || value is String) {
        result[entry.key] = value;
      }
    }
    return result;
  }
}
