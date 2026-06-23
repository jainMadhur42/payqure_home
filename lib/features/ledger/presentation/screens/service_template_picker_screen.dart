import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/service_template_catalog.dart';

class ServiceTemplatePickerScreen extends StatelessWidget {
  const ServiceTemplatePickerScreen({
    required this.selectedTemplateId,
    this.onSelected,
    this.embedded = false,
    super.key,
  });

  final String selectedTemplateId;
  final ValueChanged<ServiceTemplateDefinition>? onSelected;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final templatesByCategory = {
      for (final category in ServiceTemplateCategory.values)
        category: ServiceTemplateCatalog.templates
            .where((template) => template.category == category)
            .toList(growable: false),
    };
    final content = ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Select service',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose the household service you want to track.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final category in ServiceTemplateCategory.values) ...[
          Text(
            category.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (category == ServiceTemplateCategory.custom) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Create your own service using the option that fits it best.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < templatesByCategory[category]!.length;
                  index++
                )
                  _TemplateTile(
                    template: templatesByCategory[category]![index],
                    isSelected:
                        templatesByCategory[category]![index].id ==
                        selectedTemplateId,
                    isLast: index == templatesByCategory[category]!.length - 1,
                    onTap: () =>
                        _select(context, templatesByCategory[category]![index]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
    if (embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Select service')),
      body: content,
    );
  }

  void _select(BuildContext context, ServiceTemplateDefinition template) {
    HapticFeedback.selectionClick();
    final callback = onSelected;
    if (callback != null) {
      callback(template);
      return;
    }
    Navigator.pop(context, template);
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  final ServiceTemplateDefinition template;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
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
              child: Text(template.emoji, style: const TextStyle(fontSize: 23)),
            ),
            title: Text(
              template.title,
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
