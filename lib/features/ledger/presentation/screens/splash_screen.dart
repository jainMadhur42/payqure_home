import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../common/widgets/app_logo_mark.dart';
import '../../../../core/theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onDone, super.key});

  final VoidCallback onDone;

  // Cohesive brand-purple backgrounds (no near-black) so the splash reads as a
  // single surface instead of a dark band around a purple gradient.
  static const _darkTop = Color(0xFF2E2257);
  static const _darkBottom = Color(0xFF1B1440);
  static const _lightTop = Colors.white;
  static const _lightBottom = Color(0xFFF2EEFF);

  /// Painted behind the status/navigation bars while the splash is visible so
  /// those regions blend with the gradient instead of showing the dark
  /// scaffold background.
  static Color scaffoldBackground(bool isDark) =>
      isDark ? const Color(0xFF241B4C) : Colors.white;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), _finish);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    if (!mounted || _completed) {
      return;
    }
    _completed = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _finish,
        child: Container(
          key: const ValueKey('splash-background'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      SplashScreen._darkTop,
                      SplashScreen._darkBottom,
                    ]
                  : const [
                      SplashScreen._lightTop,
                      SplashScreen._lightBottom,
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const AppLogoMark(size: 104),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Payqure Home',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Track daily services. Settle monthly bills easily.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
