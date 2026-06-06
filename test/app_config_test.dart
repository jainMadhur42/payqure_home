import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/config/app_config.dart';

void main() {
  test('uses the configured Supabase project by default', () {
    final config = AppConfig.fromEnvironment();

    expect(config.hasSupabase, isTrue);
    expect(config.supabaseUrl, AppConfig.defaultSupabaseUrl);
    expect(
      config.supabasePublishableKey,
      AppConfig.defaultSupabasePublishableKey,
    );
  });
}
