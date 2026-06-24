import 'dart:io';

/// Reads the OS name and version on platforms that expose `dart:io`
/// (Android, iOS, desktop).
String? deviceOs() {
  try {
    final os = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    final value = '$os $version'.trim();
    return value.isEmpty ? null : value;
  } catch (_) {
    return null;
  }
}
