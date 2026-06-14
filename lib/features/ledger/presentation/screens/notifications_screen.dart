import 'package:flutter/material.dart';

import '../../../../common/widgets/app_switch.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_metadata.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/services/service_reminder_planner.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/service_icon.dart';
import '../widgets/service_reminder_editor.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final services =
        controller.overview?.services ?? const <HouseholdService>[];
    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No service reminders',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add a service before creating a notification schedule.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Service reminders',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Manage when each service should remind you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...services.map(
          (service) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ServiceNotificationCard(
              service: service,
              onToggle: (enabled) => _toggle(context, service, enabled),
              onEdit: () => _edit(context, service),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    HouseholdService service,
    bool enabled,
  ) async {
    final metadata = ServiceMetadata.parse(service.description);
    if (!enabled) {
      await controller.updateServiceReminder(
        service: service,
        serviceTime: metadata.serviceTime,
        remindBeforeMinutes: 0,
      );
      return;
    }
    if (metadata.serviceTime.isEmpty) {
      await _edit(context, service);
      return;
    }
    await controller.updateServiceReminder(
      service: service,
      serviceTime: metadata.serviceTime,
      remindBeforeMinutes: metadata.remindBeforeMinutes > 0
          ? metadata.remindBeforeMinutes
          : 15,
    );
  }

  Future<void> _edit(BuildContext context, HouseholdService service) async {
    final metadata = ServiceMetadata.parse(service.description);
    final value = await showServiceReminderBottomSheet(
      context: context,
      serviceName: service.name,
      initialValue: ServiceReminderValue(
        serviceTime: metadata.serviceTime,
        remindBeforeMinutes: metadata.remindBeforeMinutes,
      ),
    );
    if (value == null) {
      return;
    }
    await controller.updateServiceReminder(
      service: service,
      serviceTime: value.serviceTime,
      remindBeforeMinutes: value.remindBeforeMinutes,
    );
  }
}

class ServiceNotificationCard extends StatelessWidget {
  const ServiceNotificationCard({
    required this.service,
    required this.onToggle,
    required this.onEdit,
    super.key,
  });

  final HouseholdService service;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final metadata = ServiceMetadata.parse(service.description);
    final enabled =
        metadata.serviceTime.isNotEmpty && metadata.remindBeforeMinutes > 0;
    final plan = enabled
        ? const ServiceReminderPlanner().planFor(
            service,
            now: metadata.startDate ?? DateTime.now(),
          )
        : null;
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  ServiceIcon(
                    icon: service.icon,
                    color: service.templateType.color,
                    serviceName: service.name,
                    templateType: service.templateType,
                    size: 48,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          enabled
                              ? plan == null
                                    ? 'Reminder schedule configured'
                                    : _scheduleLabel(plan, metadata)
                              : metadata.serviceTime.isEmpty
                              ? 'No service time configured'
                              : 'Reminder is off',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  AppSwitch(value: enabled, onChanged: onToggle),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    enabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 18,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      enabled
                          ? 'Service at ${metadata.serviceTime}'
                          : 'Tap to configure timing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Change time'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(ServiceReminderPlan plan, ServiceMetadata metadata) {
    final period = plan.hour >= 12 ? 'PM' : 'AM';
    final hour = plan.hour % 12 == 0 ? 12 : plan.hour % 12;
    final minute = plan.minute.toString().padLeft(2, '0');
    return 'Daily at $hour:$minute $period · '
        '${_reminderLabel(metadata.remindBeforeMinutes)}';
  }

  String _reminderLabel(int minutes) {
    return switch (minutes) {
      60 => '1 hour before',
      120 => '2 hours before',
      _ => '$minutes minutes before',
    };
  }
}
