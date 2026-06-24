import 'package:flutter/material.dart';

import '../../../../core/theme/accent_color.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class LedgerBottomNav extends StatelessWidget {
  const LedgerBottomNav({
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      onAdd: onAdd,
      items: const [
        AppBottomNavItem(
          index: 0,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Home',
        ),
        AppBottomNavItem(
          index: 1,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Settings',
        ),
      ],
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
    required this.items,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeItem = items[0];
    final moreItem = items[1];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Theme.of(context).dividerColor
                  : AppColors.line.withValues(alpha: 0.62),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _BottomNavDestination(
                  item: homeItem,
                  isSelected: selectedIndex == homeItem.index,
                  onTap: () => onSelected(homeItem.index),
                ),
              ),
              AppCenterAddButton(onPressed: onAdd),
              Expanded(
                child: _BottomNavDestination(
                  item: moreItem,
                  isSelected: selectedIndex == moreItem.index,
                  onTap: () => onSelected(moreItem.index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppCenterAddButton extends StatelessWidget {
  const AppCenterAddButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          elevation: 5,
          shadowColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.28),
        ),
        child: const Icon(Icons.add, size: 27),
      ),
    );
  }
}

class _BottomNavDestination extends StatelessWidget {
  const _BottomNavDestination({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 36,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? theme.colorScheme.primaryContainer
                          : context.accent.soft)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 23,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
