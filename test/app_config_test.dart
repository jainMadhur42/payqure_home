import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/config/app_config.dart';

void main() {
  test('uses debug configuration in a test build', () {
    final config = AppConfig.fromEnvironment();

    expect(config.hasSupabase, isTrue);
    expect(config.environment, AppEnvironment.debug);
    expect(config.supabaseUrl, AppConfig.debugSupabaseUrl);
    expect(
      config.supabasePublishableKey,
      AppConfig.debugSupabasePublishableKey,
    );
    expect(config.analyticsEnabled, isFalse);
    expect(config.crashlyticsEnabled, isFalse);
    expect(config.verboseLoggingEnabled, isTrue);
  });

  test('release configuration uses its configured services and telemetry', () {
    final config = AppConfig.forEnvironment(AppEnvironment.release);

    expect(config.hasSupabase, isTrue);
    expect(config.environment, AppEnvironment.release);
    expect(config.supabaseUrl, AppConfig.releaseSupabaseUrl);
    expect(
      config.supabasePublishableKey,
      AppConfig.releaseSupabasePublishableKey,
    );
    expect(config.analyticsEnabled, isTrue);
    expect(config.crashlyticsEnabled, isTrue);
    expect(config.verboseLoggingEnabled, isFalse);
  });
}
