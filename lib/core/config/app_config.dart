import 'package:flutter/foundation.dart';

enum AppEnvironment { debug, release }

class AppConfig {
  static const debugSupabaseUrl = 'https://xqklnkqzaibwagqhvpfm.supabase.co';
  static const debugSupabasePublishableKey =
      'sb_publishable_sr96_9dOCRnxphqD4mkKMg_iWpeRP_x';
  static const releaseSupabaseUrl = 'https://rhjxissoqjlthznivwut.supabase.co';
  static const releaseSupabasePublishableKey =
      'sb_publishable_YkKDhIRCp80aOv24R7IB0Q_wUpkXv6i';

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.analyticsEnabled,
    required this.crashlyticsEnabled,
    required this.verboseLoggingEnabled,
  });

  factory AppConfig.fromEnvironment() {
    const environmentOverride = String.fromEnvironment('APP_ENV');
    const environmentUrl = String.fromEnvironment('SUPABASE_URL');
    const environmentKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const analyticsOverride = String.fromEnvironment('ANALYTICS_ENABLED');
    const crashlyticsOverride = String.fromEnvironment('CRASHLYTICS_ENABLED');
    const verboseLoggingOverride = String.fromEnvironment(
      'VERBOSE_LOGGING_ENABLED',
    );

    final environment = switch (environmentOverride.toLowerCase()) {
      'debug' => AppEnvironment.debug,
      'release' => AppEnvironment.release,
      _ => kReleaseMode ? AppEnvironment.release : AppEnvironment.debug,
    };
    final defaults = AppConfig.forEnvironment(environment);

    return defaults.copyWith(
      supabaseUrl: environmentUrl.isEmpty ? null : environmentUrl,
      supabasePublishableKey: environmentKey.isEmpty ? null : environmentKey,
      analyticsEnabled: _parseBoolOverride(analyticsOverride),
      crashlyticsEnabled: _parseBoolOverride(crashlyticsOverride),
      verboseLoggingEnabled: _parseBoolOverride(verboseLoggingOverride),
    );
  }

  factory AppConfig.forEnvironment(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.debug => const AppConfig(
        environment: AppEnvironment.debug,
        supabaseUrl: debugSupabaseUrl,
        supabasePublishableKey: debugSupabasePublishableKey,
        analyticsEnabled: false,
        crashlyticsEnabled: false,
        verboseLoggingEnabled: true,
      ),
      AppEnvironment.release => const AppConfig(
        environment: AppEnvironment.release,
        supabaseUrl: releaseSupabaseUrl,
        supabasePublishableKey: releaseSupabasePublishableKey,
        analyticsEnabled: true,
        crashlyticsEnabled: true,
        verboseLoggingEnabled: false,
      ),
    };
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool analyticsEnabled;
  final bool crashlyticsEnabled;
  final bool verboseLoggingEnabled;

  bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  bool get isRelease => environment == AppEnvironment.release;

  AppConfig copyWith({
    String? supabaseUrl,
    String? supabasePublishableKey,
    bool? analyticsEnabled,
    bool? crashlyticsEnabled,
    bool? verboseLoggingEnabled,
  }) {
    return AppConfig(
      environment: environment,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabasePublishableKey:
          supabasePublishableKey ?? this.supabasePublishableKey,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashlyticsEnabled: crashlyticsEnabled ?? this.crashlyticsEnabled,
      verboseLoggingEnabled:
          verboseLoggingEnabled ?? this.verboseLoggingEnabled,
    );
  }

  static bool? _parseBoolOverride(String value) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }
}
