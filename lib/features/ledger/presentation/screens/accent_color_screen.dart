import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/accent_color.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_summary.dart';
import '../controllers/ledger_controller.dart';
import 'home_screen.dart';

class AccentColorScreen extends StatelessWidget {
  const AccentColorScreen({required this.controller, super.key});

  final LedgerController controller;

  // Sample figures used only to render the live hero preview.
  static const _previewSummary = HomeMonthlySummary(
    totalDueCents: 245000,
    usageCents: 1284000,
    previousPendingCents: 320000,
    paidCents: 4865000,
    advanceCents: 50000,
    serviceCount: 4,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = controller.selectedAccentColor;
    final accents = controller.accentColors;
    final isDefault = selected == AppAccentColor.fallback;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.accent.soft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalize Your Experience',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose an accent color and see the app update instantly.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Live preview header row
        Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Live Preview',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (!isDefault)
              TextButton.icon(
                key: const ValueKey('accent-reset-default'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.selectAccentColor(AppAccentColor.fallback);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset to Default'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Reused Home hero card — updates instantly with the selected accent.
        const HomeHeroSummaryCard(summary: _previewSummary),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Choose Accent Color',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.5,
          children: [
            for (final accent in accents)
              _AccentSwatchCard(
                accent: accent,
                isSelected: accent == selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.selectAccentColor(accent);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Footer note
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.accent.soft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'This will update the look of the app including buttons, '
                  'highlights, and cards.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccentSwatchCard extends StatelessWidget {
  const _AccentSwatchCard({
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final AppAccentColor accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('accent-tile-${accent.storageKey}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? accent.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accent.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      accent.hex,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
