import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

class QuickEntryActionCard extends StatelessWidget {
  const QuickEntryActionCard({
    required this.service,
    required this.onQuickMark,
    required this.onCustomize,
    this.selectedStatus,
    super.key,
  });

  final HouseholdService service;
  final ServiceEntryStatus? selectedStatus;
  final ValueChanged<ServiceEntryStatus> onQuickMark;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Entry',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          QuickEntryActionGrid(
            service: service,
            selectedStatus: selectedStatus,
            onQuickMark: onQuickMark,
            onCustomize: onCustomize,
          ),
        ],
      ),
    );
  }
}

class QuickEntryActionGrid extends StatelessWidget {
  const QuickEntryActionGrid({
    required this.service,
    required this.onQuickMark,
    required this.onCustomize,
    this.selectedStatus,
    super.key,
  });

  final HouseholdService service;
  final ServiceEntryStatus? selectedStatus;
  final ValueChanged<ServiceEntryStatus> onQuickMark;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final isAttendance = service.templateType == ServiceTemplateType.attendance;
    final deliveredLabel = isAttendance ? 'Present' : 'Delivered';
    final missedLabel = isAttendance ? 'Absent' : 'Not Delivered';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickEntryButton(
                label: deliveredLabel,
                selected: selectedStatus == ServiceEntryStatus.delivered,
                onPressed: () => onQuickMark(ServiceEntryStatus.delivered),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickEntryButton(
                label: missedLabel,
                selected: selectedStatus == ServiceEntryStatus.notDelivered,
                onPressed: () => onQuickMark(ServiceEntryStatus.notDelivered),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isAttendance)
          Row(
            children: [
              Expanded(
                child: _QuickEntryButton(
                  label: 'Half Day',
                  selected: selectedStatus == ServiceEntryStatus.halfDay,
                  onPressed: () => onQuickMark(ServiceEntryStatus.halfDay),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickEntryButton(
                  label: 'Customize',
                  onPressed: onCustomize,
                  outlined: true,
                ),
              ),
            ],
          )
        else
          _QuickEntryButton(
            label: 'Customize',
            onPressed: onCustomize,
            outlined: true,
          ),
      ],
    );
  }
}

class _QuickEntryButton extends StatelessWidget {
  const _QuickEntryButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(onPressed: onPressed, child: labelWidget)
          : selected
          ? FilledButton(onPressed: onPressed, child: labelWidget)
          : FilledButton.tonal(onPressed: onPressed, child: labelWidget),
    );
  }
}
