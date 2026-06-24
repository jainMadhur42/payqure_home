import 'dart:io';

/// Reads the app version *name* (without the `+build` suffix) from
/// `pubspec.yaml` — the single source of truth for the app version.
///
/// Tests use this so bumping `pubspec.yaml` automatically propagates instead of
/// hardcoding the version in several places.
String readPubspecAppVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw StateError('Could not find "version:" in pubspec.yaml');
  }
  return match.group(1)!;
}
