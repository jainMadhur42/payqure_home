import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_compatibility.dart';

abstract interface class AppCompatibilityRepository {
  Future<AppCompatibilityConfig?> fetch();
}

class SupabaseAppCompatibilityRepository implements AppCompatibilityRepository {
  const SupabaseAppCompatibilityRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<AppCompatibilityConfig?> fetch() async {
    final client = _client;
    if (client == null) {
      return null;
    }
    final response = await client.rpc<Object?>('get_app_compatibility_config');
    final json = _jsonObject(response);
    return json == null ? null : AppCompatibilityConfig.fromJson(json);
  }
}

class NoopAppCompatibilityRepository implements AppCompatibilityRepository {
  const NoopAppCompatibilityRepository();

  @override
  Future<AppCompatibilityConfig?> fetch() async => null;
}

Map<String, dynamic>? _jsonObject(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  if (value is List && value.isNotEmpty) {
    return _jsonObject(value.first);
  }
  return null;
}
