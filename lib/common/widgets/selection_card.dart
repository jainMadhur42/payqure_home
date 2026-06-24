import 'package:flutter/material.dart';

import '../../core/theme/accent_color.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class SelectionCard<T> extends StatelessWidget {
  const SelectionCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.trailing,
    this.footer,
    this.borderColor,
    this.isSelected = false,
    super.key,
  });

  final T value;
  final String title;
  final Widget subtitle;
  final Widget leading;
  final Widget? trailing;
  final Widget? footer;
  final Color? borderColor;
  final bool isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedBackground = theme.brightness == Brightness.dark
        ? colorScheme.primaryContainer.withValues(alpha: 0.28)
        : context.accent.soft.withValues(alpha: 0.56);
    return Material(
      color: isSelected ? selectedBackground : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : borderColor ?? theme.dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(value),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        subtitle,
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.md),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
