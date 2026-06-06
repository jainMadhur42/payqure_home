class AppConfig {
  static const defaultSupabaseUrl = 'https://pvnwygtqsghdqyxbrnho.supabase.co';
  static const defaultSupabasePublishableKey =
      'sb_publishable_B02yGi_bAbWxfeOlY7_yHA_AGIX-gWk';

  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() {
    const environmentUrl = String.fromEnvironment('SUPABASE_URL');
    const environmentKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return AppConfig(
      supabaseUrl: environmentUrl.isEmpty ? defaultSupabaseUrl : environmentUrl,
      supabasePublishableKey: environmentKey.isEmpty
          ? defaultSupabasePublishableKey
          : environmentKey,
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
