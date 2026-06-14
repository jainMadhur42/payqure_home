import 'package:flutter/material.dart';

import '../../../../common/widgets/app_switch.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class ServiceReminderValue {
  const ServiceReminderValue({
    required this.serviceTime,
    required this.remindBeforeMinutes,
  });

  final String serviceTime;
  final int remindBeforeMinutes;

  bool get enabled => serviceTime.trim().isNotEmpty && remindBeforeMinutes > 0;
}

class ServiceReminderFields extends StatelessWidget {
  const ServiceReminderFields({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  static const reminderOptions = <int>[0, 10, 15, 30, 60, 120];

  final ServiceReminderValue value;
  final ValueChanged<ServiceReminderValue> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: enabled ? () => _pickTime(context) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Time of Service',
              suffixIcon: Icon(Icons.schedule_outlined),
            ),
            child: Text(
              value.serviceTime.isEmpty ? 'Not set' : value.serviceTime,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: value.serviceTime.isEmpty
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          key: ValueKey(
            '${value.serviceTime}:${value.remindBeforeMinutes}:$enabled',
          ),
          initialValue: value.remindBeforeMinutes,
          decoration: const InputDecoration(labelText: 'Remind me'),
          items: const [
            DropdownMenuItem(value: 0, child: Text('No reminder')),
            DropdownMenuItem(value: 10, child: Text('10 minutes before')),
            DropdownMenuItem(value: 15, child: Text('15 minutes before')),
            DropdownMenuItem(value: 30, child: Text('30 minutes before')),
            DropdownMenuItem(value: 60, child: Text('1 hour before')),
            DropdownMenuItem(value: 120, child: Text('2 hours before')),
          ],
          onChanged: !enabled || value.serviceTime.isEmpty
              ? null
              : (minutes) => onChanged(
                  ServiceReminderValue(
                    serviceTime: value.serviceTime,
                    remindBeforeMinutes: minutes ?? 0,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(value.serviceTime) ?? TimeOfDay.now(),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    onChanged(
      ServiceReminderValue(
        serviceTime: picked.format(context),
        remindBeforeMinutes: value.remindBeforeMinutes,
      ),
    );
  }

  TimeOfDay? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3)?.toUpperCase();
    if (hour == null || minute == null || minute > 59) {
      return null;
    }
    if (period == 'AM') {
      hour %= 12;
    } else if (period == 'PM' && hour != 12) {
      hour += 12;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}

Future<ServiceReminderValue?> showServiceReminderBottomSheet({
  required BuildContext context,
  required String serviceName,
  required ServiceReminderValue initialValue,
}) {
  return showModalBottomSheet<ServiceReminderValue>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServiceReminderBottomSheet(
      serviceName: serviceName,
      initialValue: initialValue,
    ),
  );
}

class _ServiceReminderBottomSheet extends StatefulWidget {
  const _ServiceReminderBottomSheet({
    required this.serviceName,
    required this.initialValue,
  });

  final String serviceName;
  final ServiceReminderValue initialValue;

  @override
  State<_ServiceReminderBottomSheet> createState() =>
      _ServiceReminderBottomSheetState();
}

class _ServiceReminderBottomSheetState
    extends State<_ServiceReminderBottomSheet> {
  late ServiceReminderValue _value;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _enabled = _value.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Notification Schedule',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.serviceName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Service reminder'),
                subtitle: Text(
                  _enabled
                      ? 'Notify me before the service time'
                      : 'No reminder will be scheduled',
                ),
                trailing: AppSwitch(value: _enabled, onChanged: _setEnabled),
                onTap: () => _setEnabled(!_enabled),
              ),
              const SizedBox(height: AppSpacing.sm),
              ServiceReminderFields(
                value: _value,
                enabled: _enabled,
                onChanged: (value) => setState(() {
                  _value = value;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save Schedule'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_enabled && _value.serviceTime.trim().isEmpty) {
      setState(() => _error = 'Choose a service time.');
      return;
    }
    if (_enabled && _value.remindBeforeMinutes <= 0) {
      setState(() => _error = 'Choose when you want to be reminded.');
      return;
    }
    Navigator.pop(
      context,
      ServiceReminderValue(
        serviceTime: _value.serviceTime,
        remindBeforeMinutes: _enabled ? _value.remindBeforeMinutes : 0,
      ),
    );
  }

  void _setEnabled(bool enabled) {
    setState(() {
      _enabled = enabled;
      _error = null;
      if (!enabled) {
        _value = ServiceReminderValue(
          serviceTime: _value.serviceTime,
          remindBeforeMinutes: 0,
        );
      } else if (_value.remindBeforeMinutes == 0) {
        _value = ServiceReminderValue(
          serviceTime: _value.serviceTime,
          remindBeforeMinutes: 15,
        );
      }
    });
  }
}
