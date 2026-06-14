import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class UnitPickerScreen extends StatelessWidget {
  const UnitPickerScreen({
    required this.units,
    required this.selectedUnit,
    required this.serviceName,
    super.key,
  });

  final List<String> units;
  final String? selectedUnit;
  final String serviceName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Select unit')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Select unit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            serviceName.isEmpty
                ? 'Choose how this service quantity is measured.'
                : 'Choose how $serviceName quantity is measured.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < units.length; index++)
                  _UnitTile(
                    unit: units[index],
                    isSelected: units[index] == selectedUnit,
                    isLast: index == units.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    required this.isSelected,
    required this.isLast,
  });

  final String unit;
  final bool isSelected;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, unit);
            },
            minLeadingWidth: 44,
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Icon(
                Icons.straighten_rounded,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                size: 21,
              ),
            ),
            title: Text(
              unit,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      key: ValueKey('selected'),
                      color: AppColors.primary,
                    )
                  : const Icon(
                      Icons.chevron_right,
                      key: ValueKey('unselected'),
                    ),
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 72, color: colorScheme.outlineVariant),
      ],
    );
  }
}
