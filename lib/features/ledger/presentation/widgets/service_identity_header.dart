import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/service_template.dart';
import 'service_icon.dart';

class ServiceIdentityHeader extends StatelessWidget {
  const ServiceIdentityHeader({
    required this.icon,
    required this.accentColor,
    required this.serviceName,
    required this.providerName,
    required this.templateType,
    this.contextLabel,
    this.trailing,
    this.iconSize = 44,
    super.key,
  });

  final String icon;
  final Color accentColor;
  final String serviceName;
  final String providerName;
  final ServiceTemplateType templateType;
  final String? contextLabel;
  final Widget? trailing;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceIcon(
          icon: icon,
          color: accentColor,
          serviceName: serviceName,
          templateType: templateType,
          size: iconSize,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                'Provider: $providerName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
              Text(
                [
                  if (contextLabel?.trim().isNotEmpty == true)
                    contextLabel!.trim(),
                  templateType.label,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
