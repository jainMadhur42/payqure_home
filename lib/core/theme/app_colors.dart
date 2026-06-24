import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand purple — also the default user accent (#7C3AED). Used for brand
  // surfaces (onboarding/splash-adjacent) and as the fallback accent.
  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFF5B21B6);
  static const primarySoft = Color(0xFFEDE9FE);
  static const success = Color(0xFF0E9F52);
  static const successSoft = Color(0xFFE5F7EC);
  static const warning = Color(0xFFFF6B1A);
  static const warningSoft = Color(0xFFFFF0E8);
  static const danger = Color(0xFFE72646);
  static const dangerSoft = Color(0xFFFFE8EC);
  static const info = Color(0xFF1668E8);
  static const infoSoft = Color(0xFFE8F0FF);
  static const ink = Color(0xFF101429);
  static const muted = Color(0xFF6F7488);
  static const line = Color(0xFFE4E7F0);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8F9FF);
}
