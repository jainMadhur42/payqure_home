import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/accent_color.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/ledger_controller.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Select theme',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose how Payqure Home appears on this device.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < ThemeMode.values.length; index++) ...[
                _ThemeTile(
                  mode: ThemeMode.values[index],
                  selected: controller.selectedThemeMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.selectThemeMode(ThemeMode.values[index]);
                  },
                ),
                if (index != ThemeMode.values.length - 1)
                  Divider(
                    height: 1,
                    indent: 72,
                    color: Theme.of(context).dividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final ThemeMode selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selected;
    return ListTile(
      onTap: onTap,
      minLeadingWidth: 44,
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? context.accent.soft
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          switch (mode) {
            ThemeMode.light => Icons.light_mode_outlined,
            ThemeMode.dark => Icons.dark_mode_outlined,
            ThemeMode.system => Icons.settings_brightness_outlined,
          },
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      title: Text(
        switch (mode) {
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
          ThemeMode.system => 'System preference',
        },
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(switch (mode) {
        ThemeMode.light => 'Always use the light appearance',
        ThemeMode.dark => 'Always use the dark appearance',
        ThemeMode.system => 'Match your device appearance',
      }),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isSelected
            ? Icon(
                Icons.check_circle,
                key: const ValueKey('selected'),
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(
                Icons.chevron_right,
                key: ValueKey('unselected'),
                color: AppColors.muted,
              ),
      ),
    );
  }
}
