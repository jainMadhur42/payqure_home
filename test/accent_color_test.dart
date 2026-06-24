import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payqure_home/core/theme/accent_color.dart';
import 'package:payqure_home/core/theme/app_theme.dart';

void main() {
  test('default and fallback accent is Brand Purple #7C3AED', () {
    expect(AppAccentColor.fallback, AppAccentColor.brandPurple);
    expect(AppAccentColor.brandPurple.color, const Color(0xFF7C3AED));
  });

  test('fromStorageKey round-trips and falls back for unknown/null keys', () {
    for (final accent in AppAccentColor.values) {
      expect(AppAccentColor.fromStorageKey(accent.storageKey), accent);
    }
    expect(AppAccentColor.fromStorageKey(null), AppAccentColor.brandPurple);
    expect(
      AppAccentColor.fromStorageKey('does_not_exist'),
      AppAccentColor.brandPurple,
    );
  });

  test('AppTheme primary follows the selected accent (light + dark)', () {
    for (final accent in AppAccentColor.values) {
      final light = AppTheme.light(accent.color);
      expect(light.colorScheme.primary, accent.color);
      expect(light.extension<AppAccent>(), isNotNull);
      // Dark mode brightens the accent, so it should differ but still exist.
      final dark = AppTheme.dark(accent.color);
      expect(dark.extension<AppAccent>(), isNotNull);
      expect(dark.brightness, Brightness.dark);
    }
  });

  test('default theme (no accent) uses the brand purple', () {
    expect(AppTheme.light().colorScheme.primary, AppAccentColor.brandPurple.color);
  });
}
