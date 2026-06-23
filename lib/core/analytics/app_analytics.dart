import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract interface class AnalyticsService {
  void logEvent(String name, {Map<String, Object?> parameters = const {}});
  void setUserProperty(String name, String? value);
  void setUserProperties(Map<String, Object?> properties);
  void logScreenView(String screenName);
}

abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const signupStarted = 'signup_started';
  static const signupCompleted = 'signup_completed';
  static const loginStarted = 'login_started';
  static const loginCompleted = 'login_completed';
  static const logoutClicked = 'logout_clicked';
  static const passwordResetStarted = 'password_reset_started';
  static const passwordResetCompleted = 'password_reset_completed';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingScreenViewed = 'onboarding_screen_viewed';
  static const onboardingSkipped = 'onboarding_skipped';
  static const onboardingCompleted = 'onboarding_completed';
  static const addServiceStarted = 'add_service_started';
  static const serviceTemplateSelected = 'service_template_selected';
  static const serviceCreated = 'service_created';
  static const serviceCreationFailed = 'service_creation_failed';
  static const serviceUpdated = 'service_updated';
  static const serviceDeleted = 'service_deleted';
  static const dailyEntryStarted = 'daily_entry_started';
  static const dailyEntryLogged = 'daily_entry_logged';
  static const dailyEntryUpdated = 'daily_entry_updated';
  static const dailyEntryDeleted = 'daily_entry_deleted';
  static const dailyEntryFailed = 'entry_log_failed';
  static const futureEntryBlocked = 'future_entry_blocked';
  static const quickLogOpened = 'quick_log_opened';
  static const quickLogEntryLogged = 'quick_log_entry_logged';
  static const quickLogCompleted = 'quick_log_completed';
  static const calendarOpened = 'calendar_opened';
  static const calendarDateSelected = 'calendar_date_selected';
  static const calendarMonthChanged = 'calendar_month_changed';
  static const paymentScreenOpened = 'payment_screen_opened';
  static const paymentRecordStarted = 'payment_record_started';
  static const paymentRecorded = 'payment_recorded';
  static const paymentRecordFailed = 'payment_record_failed';
  static const paymentUpdated = 'payment_updated';
  static const paymentDeleted = 'payment_deleted';
  static const creditAdded = 'credit_added';
  static const paymentHistoryOpened = 'payment_history_opened';
  static const billingSummaryOpened = 'billing_summary_opened';
  static const pdfGenerationStarted = 'pdf_generation_started';
  static const pdfGenerated = 'pdf_generated';
  static const pdfGenerationFailed = 'pdf_generation_failed';
  static const pdfShared = 'pdf_shared';
  static const contactsOpened = 'contacts_opened';
  static const providerCallClicked = 'provider_call_clicked';
  static const providerContactCopied = 'provider_contact_copied';
  static const moreTabOpened = 'more_tab_opened';
  static const profileOpened = 'profile_opened';
  static const privacyPolicyOpened = 'privacy_policy_opened';
  static const termsOpened = 'terms_opened';
  static const deleteAccountOpened = 'delete_account_opened';
  static const deleteAccountRequested = 'delete_account_requested';
  static const offlineModeDetected = 'offline_mode_detected';
  static const syncStarted = 'sync_started';
  static const syncCompleted = 'sync_completed';
  static const syncFailed = 'sync_failed';
  static const localChangePending = 'local_change_pending';

  // Compatibility aliases keep event usage centralized while emitting the
  // current product taxonomy.
  static const signUpStarted = signupStarted;
  static const signUpCompleted = signupCompleted;
  static const forgotPasswordStarted = passwordResetStarted;
  static const forgotPasswordCompleted = passwordResetCompleted;
  static const entryCreated = dailyEntryLogged;
  static const entryUpdated = dailyEntryUpdated;
  static const entryDeleted = dailyEntryDeleted;
  static const calendarDateTapped = calendarDateSelected;
  static const recordPaymentStarted = paymentRecordStarted;
  static const paymentHistoryViewed = paymentHistoryOpened;
  static const advanceAdded = creditAdded;
  static const pdfGenerateStarted = pdfGenerationStarted;
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
  static const platform = 'platform';
  static const serviceNature = 'service_nature';
  static const autoMarkEnabled = 'auto_mark_enabled';
  static const hasReminder = 'has_reminder';
  static const hasContactNumber = 'has_contact_number';
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
  static const dateRelation = 'date_relation';
  static const quantityBucket = 'quantity_bucket';
  static const quantityChanged = 'quantity_changed';
  static const rateChanged = 'rate_changed';
  static const quantity = 'quantity';
  static const entryAmountBucket = 'entry_amount_bucket';
  static const paymentMode = 'payment_mode';
  static const paymentResult = 'payment_result';
  static const source = 'source';
  static const amountBucket = 'amount_bucket';
  static const monthType = 'month_type';
  static const monthOffset = 'month_offset';
  static const paymentType = 'payment_type';
  static const entityType = 'entity_type';
  static const operation = 'operation';
  static const errorType = 'error_type';
  static const pendingCount = 'pending_count';
  static const totalServices = 'total_services';
  static const loggedCount = 'logged_count';
  static const serviceCountBucket = 'service_count_bucket';
  static const hasCreatedService = 'has_created_service';
  static const hasLoggedEntry = 'has_logged_entry';
  static const hasRecordedPayment = 'has_recorded_payment';
  static const preferredServiceType = 'preferred_service_type';
  static const serviceCount = 'service_count';
  static const hasQuantityService = 'has_quantity_service';
  static const hasAttendanceService = 'has_attendance_service';
  static const hasFixedMonthlyService = 'has_fixed_monthly';
  static const syncEntityType = 'sync_entity_type';
}

abstract final class AmountAnalyticsHelper {
  static String getAmountBucket(num amount) {
    final normalized = amount.abs();
    if (normalized <= 100) return '0_100';
    if (normalized <= 500) return '100_500';
    if (normalized <= 1000) return '500_1000';
    if (normalized <= 5000) return '1000_5000';
    return '5000_plus';
  }

  static String centsBucket(int cents) => getAmountBucket(cents / 100);

  static String getQuantityBucket(num quantity) {
    final normalized = quantity.abs();
    if (normalized <= 1) return '0_1';
    if (normalized <= 5) return '1_5';
    if (normalized <= 10) return '5_10';
    return '10_plus';
  }

  static String getCountBucket(int count) {
    if (count <= 0) return '0';
    if (count <= 3) return '1_3';
    if (count <= 6) return '4_6';
    if (count <= 10) return '7_10';
    return '10_plus';
  }
}

class AppAnalytics implements AnalyticsService {
  AppAnalytics._({
    FirebaseAnalytics? analytics,
    this._crashlytics,
    bool enabled = true,
  }) : _analytics = analytics,
       _enabled = enabled && analytics != null;

  factory AppAnalytics.disabled() => AppAnalytics._(enabled: false);

  static Future<AppAnalytics> initialize({
    bool analyticsEnabled = true,
    bool crashlyticsEnabled = true,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final analytics = FirebaseAnalytics.instance;
      final crashlytics = FirebaseCrashlytics.instance;
      await analytics.setAnalyticsCollectionEnabled(analyticsEnabled);
      await crashlytics.setCrashlyticsCollectionEnabled(crashlyticsEnabled);
      if (crashlyticsEnabled) {
        FlutterError.onError = (details) {
          unawaited(crashlytics.recordFlutterFatalError(details));
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(crashlytics.recordError(error, stack, fatal: true));
          return true;
        };
      }
      return AppAnalytics._(
        analytics: analyticsEnabled ? analytics : null,
        crashlytics: crashlyticsEnabled ? crashlytics : null,
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

  @override
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    final sanitized = _sanitizeParameters(parameters);
    if (kDebugMode) {
      debugPrint('[Analytics] $name $sanitized');
    }
    if (!_enabled) return;
    unawaited(
      _guard(() => _analytics!.logEvent(name: name, parameters: sanitized)),
    );
  }

  @override
  void setUserProperty(String name, String? value) {
    if (_isSensitiveKey(name)) return;
    if (kDebugMode) {
      debugPrint('[Analytics] user_property $name=$value');
    }
    if (!_enabled) return;
    unawaited(
      _guard(() => _analytics!.setUserProperty(name: name, value: value)),
    );
  }

  @override
  void setUserProperties(Map<String, Object?> properties) {
    for (final entry in _sanitizeParameters(properties).entries) {
      setUserProperty(entry.key, entry.value.toString());
    }
  }

  @override
  void logScreenView(String screenName) {
    if (kDebugMode) {
      debugPrint('[Analytics] screen_view $screenName');
    }
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
      if (_isSensitiveKey(entry.key)) continue;
      final value = entry.value;
      if (value == null) continue;
      if (value is bool || value is num || value is String) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  @visibleForTesting
  Map<String, Object> sanitizeParametersForTesting(
    Map<String, Object?> parameters,
  ) {
    return _sanitizeParameters(parameters);
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return const {
      'email',
      'phone',
      'phone_number',
      'contact_number',
      'provider_name',
      'user_name',
      'name',
      'address',
      'note',
    }.contains(normalized);
  }
}
