import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/app_snack_bar.dart';
import '../../../../common/widgets/app_switch.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_metadata.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../../domain/services/entry_value_resolver.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_calendar.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/quick_entry_actions.dart';
import '../widgets/service_icon.dart';
import '../widgets/service_reminder_editor.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    final serviceStartDate = const ServiceStartDateResolver().resolve(service);
    final selectedEntry = service.entries
        .where((entry) => entry.day == controller.selectedDay)
        .firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        ServiceDetailSummaryCard(controller: controller, service: service),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LedgerCalendar(
            entries: service.entries,
            monthKey: service.monthKey,
            configuredQuantity:
                service.templateType == ServiceTemplateType.quantity
                ? service.defaultQuantity
                : null,
            selectedDay: controller.selectedDay,
            serviceStartDate: serviceStartDate,
            onDaySelected: (day) => _handleDayTap(context, day),
            onBlockedDaySelected: (date) =>
                _showBlockedDateMessage(context, date, serviceStartDate),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        QuickEntryActionCard(
          service: service,
          selectedEntry: selectedEntry,
          selectedStatus: selectedEntry?.status,
          onQuickMark: (status) {
            if (!_canEditSelectedDay(context, serviceStartDate)) {
              return;
            }
            _saveQuickAction(day: controller.selectedDay, status: status);
          },
          onCustomize: () {
            if (!_canEditSelectedDay(context, serviceStartDate)) {
              return;
            }
            controller.customizeEntryForService(
              service: service,
              day: controller.selectedDay,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SelectedDayDetailCard(
          day: controller.selectedDay,
          monthKey: service.monthKey,
          service: service,
          entry: selectedEntry,
        ),
        const SizedBox(height: AppSpacing.md),
        ServiceReminderDetailCard(
          service: service,
          onToggle: (enabled) => _toggleReminder(context, service, enabled),
          onEdit: () => _editReminder(context, service),
        ),
      ],
    );
  }

  void _handleDayTap(BuildContext context, int day) {
    controller.selectDayInline(day);
  }

  void _showServiceStartMessage(
    BuildContext context,
    DateTime? serviceStartDate,
  ) {
    if (serviceStartDate == null) {
      return;
    }
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][serviceStartDate.month - 1];
    _showSnackBar(
      context,
      'Service started from ${serviceStartDate.day} $month ${serviceStartDate.year} '
      'can not update delivery before that. Edit service started date to mark '
      'the entry.',
    );
  }

  void _showBlockedDateMessage(
    BuildContext context,
    DateTime date,
    DateTime? serviceStartDate,
  ) {
    if (_isFutureDate(date)) {
      controller.trackFutureEntryBlocked(service: service, day: date.day);
      _showSnackBar(
        context,
        'Entries can only be logged on or after the service date.',
      );
      return;
    }
    _showServiceStartMessage(context, serviceStartDate);
  }

  bool _canEditSelectedDay(BuildContext context, DateTime? serviceStartDate) {
    final month = LedgerMonth.parse(service.monthKey);
    final selectedDate = DateTime(
      month.year,
      month.month,
      controller.selectedDay,
    );
    if (_isFutureDate(selectedDate)) {
      controller.trackFutureEntryBlocked(
        service: service,
        day: selectedDate.day,
      );
      _showSnackBar(
        context,
        'Entries can only be logged on or after the service date.',
      );
      return false;
    }
    if (serviceStartDate != null) {
      final start = DateTime(
        serviceStartDate.year,
        serviceStartDate.month,
        serviceStartDate.day,
      );
      if (selectedDate.isBefore(start)) {
        _showServiceStartMessage(context, serviceStartDate);
        return false;
      }
    }
    return true;
  }

  bool _isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).isAfter(today);
  }

  void _showSnackBar(BuildContext context, String message) {
    AppSnackBar.show(context, message: message, tone: AppSnackBarTone.warning);
  }

  Future<void> _saveQuickAction({
    required int day,
    required ServiceEntryStatus status,
  }) async {
    HapticFeedback.lightImpact();
    await controller.saveQuickEntryForService(
      service: service,
      day: day,
      status: status,
    );
  }

  Future<void> _toggleReminder(
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
      await _editReminder(context, service);
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

  Future<void> _editReminder(
    BuildContext context,
    HouseholdService service,
  ) async {
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

class ServiceReminderDetailCard extends StatelessWidget {
  const ServiceReminderDetailCard({
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
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Reminder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? '${metadata.serviceTime} · ${_reminderLabel(metadata.remindBeforeMinutes)}'
                          : 'No notification scheduled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppSwitch(value: enabled, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.schedule_outlined, size: 18),
              label: Text(enabled ? 'Change time' : 'Set reminder'),
            ),
          ),
        ],
      ),
    );
  }

  static String _reminderLabel(int minutes) {
    return switch (minutes) {
      60 => '1 hour before',
      120 => '2 hours before',
      _ => '$minutes minutes before',
    };
  }
}

class SelectedDayDetailCard extends StatelessWidget {
  const SelectedDayDetailCard({
    required this.day,
    required this.monthKey,
    required this.service,
    required this.entry,
    super.key,
  });

  final int day;
  final String monthKey;
  final HouseholdService service;
  final ServiceEntry? entry;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullDateLabel(day, monthKey),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          _EntryCalculation(service: service, entry: entry),
          if (entry?.note.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              entry!.note,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCalculation extends StatelessWidget {
  const _EntryCalculation({required this.service, required this.entry});

  final HouseholdService service;
  final ServiceEntry? entry;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final resolved = entry == null
        ? null
        : const EntryValueResolver().resolve(service: service, entry: entry);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: _quantityLabel(entry)),
              const TextSpan(text: ' × '),
              TextSpan(
                text: CurrencyFormatter.cents(
                  resolved?.rateCents ?? _fallbackRateCents(),
                ),
              ),
              const TextSpan(text: ' = '),
              TextSpan(
                text: CurrencyFormatter.cents(resolved?.amountCents ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          maxLines: 1,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _quantityLabel(ServiceEntry? entry) {
    final quantity = entry?.quantity ?? 0;
    final formatted = quantity.truncateToDouble() == quantity
        ? quantity.toStringAsFixed(0)
        : quantity
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    final entryUnit = entry?.unit.trim() ?? '';
    final unit = entryUnit.isNotEmpty ? entryUnit : service.unit.trim();
    return unit.isEmpty ? formatted : '$formatted $unit';
  }

  int _fallbackRateCents() {
    if (service.templateType == ServiceTemplateType.fixedMonthly ||
        (service.templateType == ServiceTemplateType.attendance &&
            service.monthlyAmountCents > 0)) {
      return service.monthlyAmountCents;
    }
    return service.rateCents;
  }
}

class ServiceDetailSummaryCard extends StatelessWidget {
  const ServiceDetailSummaryCard({
    required this.controller,
    required this.service,
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.loadTillDateSummaryForService(service),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final usage = summary?.usage;
        final settlement = summary?.settlement;
        final deliveredDays = usage?.deliveredDays ?? 0;
        final missedDays = usage?.missedDays ?? 0;
        final totalQuantity = usage?.totalQuantity ?? 0;
        final quantity = totalQuantity.toStringAsFixed(
          totalQuantity.truncateToDouble() == totalQuantity ? 0 : 1,
        );
        final metric = service.templateType == ServiceTemplateType.attendance
            ? '$deliveredDays Present'
            : service.templateType == ServiceTemplateType.fixedMonthly
            ? 'Fixed Monthly'
            : '$quantity${service.unit.trim().isEmpty ? '' : ' ${service.unit.trim()}'}';
        final dueLabel = _isCurrentMonth(controller.monthKey)
            ? 'Due till today'
            : 'Monthly Due';
        final currentMonthCharges = settlement?.usageAmountCents ?? 0;
        final previousBalance = settlement?.previousBalanceRemainingCents ?? 0;
        final advancePaidThisMonth =
            settlement?.advanceCreatedThisMonthCents ?? 0;
        final paidThisMonth = settlement?.paidThisMonthCents ?? 0;
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceIcon(
                    icon: service.icon,
                    color: service.templateType.color,
                    serviceName: service.name,
                    templateType: service.templateType,
                    size: 52,
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SummaryChip(
                          label: service.templateType.label,
                          value: '',
                          color: service.templateType.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatementMetric(
                      label: dueLabel,
                      value: CurrencyFormatter.rupees(
                        (settlement?.carryForwardCents ?? 0) / 100,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _StatementMetric(label: 'Activity', value: metric),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatementMetric(
                      label: 'Current month',
                      value: CurrencyFormatter.rupees(
                        currentMonthCharges / 100,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _StatementMetric(
                      label: 'Previous balance',
                      value: CurrencyFormatter.rupees(previousBalance / 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatementMetric(
                      label: 'Advance this month',
                      value: CurrencyFormatter.rupees(
                        advancePaidThisMonth / 100,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _StatementMetric(
                      label: 'Paid this month',
                      value: CurrencyFormatter.rupees(paidThisMonth / 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatementMetric(
                      label: 'Delivered',
                      value: '$deliveredDays',
                    ),
                  ),
                  Expanded(
                    child: _StatementMetric(
                      label: 'Missed',
                      value: '$missedDays',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isCurrentMonth(String monthKey) {
    return LedgerMonth.parse(monthKey) == LedgerMonth.fromDate(DateTime.now());
  }
}

class _StatementMetric extends StatelessWidget {
  const _StatementMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class EntryView extends StatefulWidget {
  const EntryView({required this.controller, required this.service, super.key});

  final LedgerController controller;
  final HouseholdService service;

  @override
  State<EntryView> createState() => EntryViewState();
}

class EntryViewState extends State<EntryView> {
  // Keeps a focused field scrolled clear of the floating "Save Entry" button.
  static const _entryScrollPadding = EdgeInsets.only(bottom: 96);

  late ServiceEntryStatus _status;
  late bool _customSelected;
  late final TextEditingController _quantityController;
  late final TextEditingController _rateController;
  late final TextEditingController _noteController;
  String? _quantityError;
  String? _rateError;

  @override
  void initState() {
    super.initState();
    final entry = widget.service.entries
        .where((entry) => entry.day == widget.controller.selectedDay)
        .firstOrNull;
    _status = entry?.status ?? ServiceEntryStatus.delivered;
    _customSelected = entry == null
        ? true
        : isCustomQuickEntry(widget.service, entry);
    _quantityController = TextEditingController(
      text: _formatQuantity(entry?.quantity ?? widget.service.defaultQuantity),
    );
    _rateController = TextEditingController(
      text: (_initialRateCents(entry) / 100).toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: entry?.note ?? '');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _effectiveQuantity;
    final rateCents = ((double.tryParse(_rateController.text) ?? 0) * 100)
        .round();
    final amount = widget.controller.calculateEntryAmount(
      service: widget.service,
      status: _status,
      quantity: quantity,
      rateCents: rateCents,
    );
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            92,
          ),
          children: [
            ScreenTitle(
              title: widget.service.name,
              subtitle: fullDateLabel(
                widget.controller.selectedDay,
                widget.controller.monthKey,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            QuickEntryActionCard(
              service: widget.service,
              selectedStatus: _status,
              customSelectedOverride: _customSelected,
              onQuickMark: _selectStatus,
              onCustomize: _selectCustom,
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _quantityController,
                    enabled:
                        widget.service.templateType ==
                            ServiceTemplateType.quantity &&
                        _status == ServiceEntryStatus.delivered,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'),
                      ),
                    ],
                    scrollPadding: _entryScrollPadding,
                    decoration: InputDecoration(
                      labelText: widget.service.unit.isEmpty
                          ? 'Quantity'
                          : 'Quantity (${widget.service.unit})',
                      suffixText: widget.service.unit.isEmpty
                          ? null
                          : widget.service.unit,
                      hintText: _formatQuantity(widget.service.defaultQuantity),
                      errorText: _quantityError,
                    ),
                    onChanged: (_) {
                      final quantity = double.tryParse(
                        _quantityController.text.trim(),
                      );
                      setState(() {
                        _status = ServiceEntryStatus.delivered;
                        _customSelected = true;
                        if (quantity != null && quantity > 0) {
                          _quantityError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _rateController,
                    enabled:
                        widget.service.templateType ==
                        ServiceTemplateType.quantity,
                    keyboardType: TextInputType.number,
                    scrollPadding: _entryScrollPadding,
                    decoration: InputDecoration(
                      labelText: _rateLabel,
                      errorText: _rateError,
                    ),
                    onChanged: (_) {
                      final rate = double.tryParse(_rateController.text.trim());
                      setState(() {
                        _status = ServiceEntryStatus.delivered;
                        _customSelected = true;
                        if (rate != null && rate >= 0) {
                          _rateError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calculated Amount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.rupees(amount.amountCents / 100),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amount.detail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 3,
                    scrollPadding: _entryScrollPadding,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      hintText: 'Extra can delivered',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => _saveEntry(context),
              child: const Center(child: Text('Save Entry')),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEntry(BuildContext context) async {
    final quantity = double.tryParse(_quantityController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());
    final requiresQuantity =
        widget.service.templateType == ServiceTemplateType.quantity &&
        _status == ServiceEntryStatus.delivered;
    final quantityError =
        requiresQuantity && (quantity == null || quantity <= 0)
        ? 'Enter a quantity greater than 0'
        : null;
    final rateError = rate == null || rate < 0 ? 'Enter a valid rate' : null;
    if (quantityError != null || rateError != null) {
      setState(() {
        _quantityError = quantityError;
        _rateError = rateError;
      });
      return;
    }
    await widget.controller.saveSelectedEntry(
      status: _status,
      quantity: _effectiveQuantity,
      unit: widget.service.unit,
      rateCents: (rate! * 100).round(),
      note: _noteController.text,
    );
  }

  double get _effectiveQuantity {
    if (_status == ServiceEntryStatus.notDelivered ||
        _status == ServiceEntryStatus.noEntry) {
      return 0;
    }
    if (_status == ServiceEntryStatus.halfDay) {
      return widget.service.defaultQuantity / 2;
    }
    return double.tryParse(_quantityController.text.trim()) ??
        widget.service.defaultQuantity;
  }

  void _selectStatus(ServiceEntryStatus status) {
    setState(() {
      _status = status;
      _customSelected = false;
      if (status == ServiceEntryStatus.delivered) {
        _quantityController.text = _formatQuantity(
          widget.service.defaultQuantity,
        );
        _rateController.text = (_initialRateCents(null) / 100).toStringAsFixed(
          0,
        );
        _quantityError = null;
        _rateError = null;
      }
    });
  }

  void _selectCustom() {
    setState(() {
      _status = ServiceEntryStatus.delivered;
      _customSelected = true;
    });
  }

  String _formatQuantity(double quantity) {
    if (quantity.truncateToDouble() == quantity) {
      return quantity.toStringAsFixed(0);
    }
    return quantity
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  int _initialRateCents(ServiceEntry? entry) {
    if (widget.service.templateType == ServiceTemplateType.attendance &&
        widget.service.monthlyAmountCents > 0) {
      return const EntryValueResolver().fixedDailyRateCents(
        service: widget.service,
        monthKey: widget.controller.monthKey,
      );
    }
    return entry?.rateCents ?? widget.service.rateCents;
  }

  String get _rateLabel {
    if (widget.service.templateType == ServiceTemplateType.attendance) {
      return 'Daily value from monthly charge (${CurrencyFormatter.symbol})';
    }
    return 'Rate (${CurrencyFormatter.symbol} / ${widget.service.unit})';
  }
}
