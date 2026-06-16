import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
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
import '../widgets/record_payment_bottom_sheet.dart';
import '../widgets/service_quick_actions_sheet.dart';
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
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            104,
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
            const StatusLegend(),
            const SizedBox(height: AppSpacing.md),
            QuickEntryActionCard(
              service: service,
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
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md,
          child: _StickyActionBar(
            onMoreActions: () => _showMoreActions(context),
          ),
        ),
      ],
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ServiceQuickActionsSheet(
        onRecordPayment: () {
          Navigator.pop(sheetContext);
          _showRecordPaymentSheet(context);
        },
        onGeneratePdf: () {
          Navigator.pop(sheetContext);
          _generatePdf(context);
        },
        onManageService: () {
          Navigator.pop(sheetContext);
          controller.openManageService(service);
        },
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context) {
    controller.trackRecordPaymentStarted(
      service: service,
      source: 'service_detail',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentBottomSheet(
        controller: controller,
        service: service,
        source: 'service_detail',
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    try {
      await controller.loadSelectedBill();
      controller.openPdfPreview(source: PdfSource.serviceDetail);
    } catch (error) {
      debugPrint('Could not generate PDF: $error');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not generate PDF. Please try again.'),
          ),
        );
    }
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
          _EntryStatusHeader(service: service, entry: entry),
          const SizedBox(height: AppSpacing.md),
          if (entry != null && entry.status != ServiceEntryStatus.noEntry) ...[
            _LoggedEntryDetails(service: service, entry: entry),
          ],
        ],
      ),
    );
  }
}

class _EntryStatusHeader extends StatelessWidget {
  const _EntryStatusHeader({required this.service, required this.entry});

  final HouseholdService service;
  final ServiceEntry? entry;

  @override
  Widget build(BuildContext context) {
    final status = entry == null || entry!.status == ServiceEntryStatus.noEntry
        ? 'No Entry'
        : entryStatusLabel(service, entry!);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(
            'Current Status',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoggedEntryDetails extends StatelessWidget {
  const _LoggedEntryDetails({required this.service, required this.entry});

  final HouseholdService service;
  final ServiceEntry entry;

  @override
  Widget build(BuildContext context) {
    final resolved = const EntryValueResolver().resolve(
      service: service,
      entry: entry,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(label: 'Status', value: entryStatusLabel(service, entry)),
        if (entry.status != ServiceEntryStatus.notDelivered) ...[
          if (service.templateType == ServiceTemplateType.attendance)
            DetailRow(
              label: 'Monthly Charge',
              value: CurrencyFormatter.rupees(
                _attendanceMonthlyAmountCents(service) / 100,
              ),
            )
          else
            DetailRow(label: 'Quantity', value: entry.quantityLabel),
          if (service.templateType != ServiceTemplateType.attendance)
            DetailRow(
              label: 'Rate',
              value:
                  '${CurrencyFormatter.rupees(resolved.rateCents / 100)}${entry.unit.isEmpty ? '' : ' / ${entry.unit}'}',
            ),
        ],
        DetailRow(
          label: 'Amount',
          value: CurrencyFormatter.rupees(resolved.amountCents / 100),
        ),
        if (entry.note.isNotEmpty) DetailRow(label: 'Note', value: entry.note),
      ],
    );
  }
}

class _StickyActionBar extends StatefulWidget {
  const _StickyActionBar({required this.onMoreActions});

  final VoidCallback onMoreActions;

  @override
  State<_StickyActionBar> createState() => _StickyActionBarState();
}

class _StickyActionBarState extends State<_StickyActionBar> {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.24
                  : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onMoreActions,
                    icon: const Icon(Icons.more_horiz, size: 18),
                    label: const Text('More'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 5.6,
        children: items
            .map((item) => LegendDot(color: item.color, label: item.label))
            .toList(),
      ),
    );
  }

  List<_LegendItem> get _items {
    return const [
      _LegendItem(AppColors.success, 'Delivered'),
      _LegendItem(AppColors.danger, 'Missed'),
      _LegendItem(AppColors.warning, 'Quantity Change'),
      _LegendItem(AppColors.muted, 'No Entry'),
    ];
  }
}

class _LegendItem {
  const _LegendItem(this.color, this.label);

  final Color color;
  final String label;
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
        final advanceBalance = settlement?.advanceBalanceCents ?? 0;
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
                      label: 'Advance balance',
                      value: CurrencyFormatter.rupees(advanceBalance / 100),
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _EntryStatusSelector(
                    options: _statusOptions,
                    value: _status,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                      color: AppColors.primary.withValues(alpha: 0.08),
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
                                color: AppColors.primary,
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

  String _formatQuantity(double quantity) {
    if (quantity.truncateToDouble() == quantity) {
      return quantity.toStringAsFixed(0);
    }
    return quantity
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String get _deliveredLabel {
    return widget.service.templateType == ServiceTemplateType.attendance
        ? 'Present'
        : 'Delivered';
  }

  String get _missedLabel {
    return widget.service.templateType == ServiceTemplateType.attendance
        ? 'Absent'
        : 'Missed';
  }

  List<_EntryStatusOption> get _statusOptions {
    return [
      _EntryStatusOption(ServiceEntryStatus.delivered, _deliveredLabel),
      _EntryStatusOption(ServiceEntryStatus.notDelivered, _missedLabel),
      if (widget.service.templateType == ServiceTemplateType.attendance)
        const _EntryStatusOption(ServiceEntryStatus.halfDay, 'Half Day'),
      const _EntryStatusOption(ServiceEntryStatus.noEntry, 'No Entry'),
    ];
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

int _attendanceMonthlyAmountCents(HouseholdService service) {
  return service.monthlyAmountCents > 0
      ? service.monthlyAmountCents
      : service.rateCents;
}

class _EntryStatusOption {
  const _EntryStatusOption(this.status, this.label);

  final ServiceEntryStatus status;
  final String label;
}

class _EntryStatusSelector extends StatelessWidget {
  const _EntryStatusSelector({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<_EntryStatusOption> options;
  final ServiceEntryStatus value;
  final ValueChanged<ServiceEntryStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_EntryStatusOption>>[
      options.take(2).toList(growable: false),
      if (options.length > 2) options.skip(2).toList(growable: false),
    ];
    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            children: [
              for (
                var optionIndex = 0;
                optionIndex < rows[rowIndex].length;
                optionIndex++
              ) ...[
                Expanded(
                  child: _EntryStatusButton(
                    option: rows[rowIndex][optionIndex],
                    selected: rows[rowIndex][optionIndex].status == value,
                    onTap: onChanged,
                  ),
                ),
                if (optionIndex < rows[rowIndex].length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          if (rowIndex < rows.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _EntryStatusButton extends StatelessWidget {
  const _EntryStatusButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _EntryStatusOption option;
  final bool selected;
  final ValueChanged<ServiceEntryStatus> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () => onTap(option.status),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          foregroundColor: selected
              ? colorScheme.onPrimary
              : colorScheme.primary,
          backgroundColor: selected
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.10),
          side: BorderSide(
            color: selected
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Center(
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
