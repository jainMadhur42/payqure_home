import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppSnackBarTone { success, error, info, warning }

abstract final class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarTone tone = AppSnackBarTone.success,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(build(context, message: message, tone: tone));
  }

  static SnackBar build(
    BuildContext context, {
    required String message,
    AppSnackBarTone tone = AppSnackBarTone.success,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(tone);
    final surface = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      padding: EdgeInsets.zero,
      dismissDirection: DismissDirection.horizontal,
      duration: const Duration(seconds: 3),
      content: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.32 : 0.14,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_icon(tone), color: accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: messengerHideCallback(context),
              icon: Icon(
                Icons.close_rounded,
                size: 19,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static VoidCallback messengerHideCallback(BuildContext context) {
    return () => ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static Color _accentColor(AppSnackBarTone tone) {
    return switch (tone) {
      AppSnackBarTone.success => AppColors.success,
      AppSnackBarTone.error => AppColors.danger,
      AppSnackBarTone.info => AppColors.primary,
      AppSnackBarTone.warning => AppColors.warning,
    };
  }

  static IconData _icon(AppSnackBarTone tone) {
    return switch (tone) {
      AppSnackBarTone.success => Icons.check_circle_rounded,
      AppSnackBarTone.error => Icons.error_rounded,
      AppSnackBarTone.info => Icons.info_rounded,
      AppSnackBarTone.warning => Icons.warning_rounded,
    };
  }
}
