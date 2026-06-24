import 'package:flutter/material.dart';

/// User-selectable accent colors. Purple stays the brand/default; the selected
/// value only drives the primary UI accent (never semantic status colors,
/// text, backgrounds, the splash screen, or the app icon).
enum AppAccentColor {
  brandPurple('brand_purple', 'Brand Purple', Color(0xFF7C3AED)),
  midnightIndigo('midnight_indigo', 'Midnight Indigo', Color(0xFF4F46E5)),
  oceanBlue('ocean_blue', 'Ocean Blue', Color(0xFF2563FF)),
  emerald('emerald', 'Emerald', Color(0xFF10B981)),
  modernTeal('modern_teal', 'Modern Teal', Color(0xFF14B8A6)),
  coralOrange('coral_orange', 'Coral Orange', Color(0xFFFF6B57)),
  rosePink('rose_pink', 'Rose Pink', Color(0xFFE11D48));

  const AppAccentColor(this.storageKey, this.label, this.color);

  /// Stable key persisted locally (decoupled from the enum name/order).
  final String storageKey;

  /// Human-readable name shown next to the swatch.
  final String label;

  /// The accent color value.
  final Color color;

  /// Uppercase `#RRGGBB` hex string for display (e.g. `#7C3AED`).
  String get hex {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Default and fallback accent — the brand purple (#7C3AED).
  static const fallback = AppAccentColor.brandPurple;

  static AppAccentColor fromStorageKey(String? key) {
    for (final accent in AppAccentColor.values) {
      if (accent.storageKey == key) {
        return accent;
      }
    }
    return fallback;
  }
}

/// Accent-derived colors exposed through [ThemeData] so widgets can read the
/// soft tint and darker variant without passing colors through constructors.
/// [primary] mirrors `colorScheme.primary`; prefer that for the base accent.
@immutable
class AppAccent extends ThemeExtension<AppAccent> {
  const AppAccent({
    required this.primary,
    required this.soft,
    required this.dark,
  });

  /// Base accent (same as `Theme.of(context).colorScheme.primary`).
  final Color primary;

  /// Light, low-emphasis tint used for chips/icon backgrounds (was primarySoft).
  final Color soft;

  /// Slightly darker accent for gradients/emphasis (was primaryDark).
  final Color dark;

  /// Derives the soft/dark variants from a single accent color so every
  /// accent stays consistent without per-color constants.
  factory AppAccent.fromSeed(Color primary, {required bool isDark}) {
    final hsl = HSLColor.fromColor(primary);
    final dark = hsl
        .withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0))
        .toColor();
    final soft = isDark
        ? primary.withValues(alpha: 0.20)
        : Color.alphaBlend(
            primary.withValues(alpha: 0.12),
            const Color(0xFFFFFFFF),
          );
    return AppAccent(primary: primary, soft: soft, dark: dark);
  }

  @override
  AppAccent copyWith({Color? primary, Color? soft, Color? dark}) {
    return AppAccent(
      primary: primary ?? this.primary,
      soft: soft ?? this.soft,
      dark: dark ?? this.dark,
    );
  }

  @override
  AppAccent lerp(ThemeExtension<AppAccent>? other, double t) {
    if (other is! AppAccent) {
      return this;
    }
    return AppAccent(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      soft: Color.lerp(soft, other.soft, t) ?? soft,
      dark: Color.lerp(dark, other.dark, t) ?? dark,
    );
  }
}

extension AppAccentContext on BuildContext {
  /// Accent colors for the current theme. Falls back to the brand purple if the
  /// extension is somehow missing so callers never crash.
  AppAccent get accent =>
      Theme.of(this).extension<AppAccent>() ??
      AppAccent.fromSeed(
        AppAccentColor.fallback.color,
        isDark: Theme.of(this).brightness == Brightness.dark,
      );
}
