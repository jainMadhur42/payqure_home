import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../../domain/services/entry_value_resolver.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/add_advance_bottom_sheet.dart';
import '../widgets/ledger_calendar.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/record_payment_bottom_sheet.dart';
import '../widgets/service_icon.dart';

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
                selectedDay: controller.selectedDay,
                serviceStartDate: serviceStartDate,
                onDaySelected: (day) => _handleDayTap(context, day),
                onBlockedDaySelected: (_) =>
                    _showServiceStartMessage(context, serviceStartDate),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const StatusLegend(),
            const SizedBox(height: AppSpacing.md),
            QuickEntryActionCard(
              service: service,
              onQuickMark: (status) =>
                  _saveQuickAction(day: controller.selectedDay, status: status),
              onCustomize: () => controller.selectDayForEdit(
                controller.selectedDay,
                source: EntrySource.calendar,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SelectedDayDetailCard(
              day: controller.selectedDay,
              monthKey: service.monthKey,
              service: service,
              entry: selectedEntry,
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
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Service',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionSheetGroup(
                children: [
                  _ActionSheetTile(
                    icon: Icons.payments_outlined,
                    title: 'Record Payment',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showRecordPaymentSheet(context);
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Add Advance',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showAdvanceBottomSheet(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionSheetGroup(
                children: [
                  _ActionSheetTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Settlement Details',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      controller.openSettlementDetail(service);
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.history_outlined,
                    title: 'Payment History',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      controller.openPaymentHistory(service);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionSheetGroup(
                children: [
                  _ActionSheetTile(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Generate PDF',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _generatePdf(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionSheetGroup(
                children: [
                  _ActionSheetTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Service',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      controller.startEditService(service);
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Service',
                    destructive: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmDeleteService(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteService(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text(
          'This will delete ${service.name} from this app and sync the deletion to Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteService(service);
    }
  }

  void _showRecordPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RecordPaymentBottomSheet(controller: controller, service: service),
    );
  }

  void _showAdvanceBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAdvanceBottomSheet(
        controller: controller,
        serviceId: service.id,
        serviceName: service.name,
        month: controller.overview?.monthLabel ?? service.monthKey,
        onSaved: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Advance payment added.')),
            );
        },
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Service started on ${serviceStartDate.day} $month ${serviceStartDate.year}. '
            'You cannot add an entry before this date.',
          ),
        ),
      );
  }

  void _saveQuickAction({
    required int day,
    required ServiceEntryStatus status,
  }) {
    HapticFeedback.lightImpact();
    controller.saveQuickEntryForService(
      service: service,
      day: day,
      status: status,
    );
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
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
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
              label: 'Daily Wage',
              value: CurrencyFormatter.rupees(resolved.rateCents / 100),
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

class QuickEntryActionCard extends StatelessWidget {
  const QuickEntryActionCard({
    required this.service,
    required this.onQuickMark,
    required this.onCustomize,
    super.key,
  });

  final HouseholdService service;
  final ValueChanged<ServiceEntryStatus> onQuickMark;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final deliveredLabel =
        service.templateType == ServiceTemplateType.attendance
        ? 'Present'
        : 'Delivered';
    final missedLabel = service.templateType == ServiceTemplateType.attendance
        ? 'Absent'
        : 'Not Delivered';
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
          Row(
            children: [
              Expanded(
                child: _QuickEntryButton(
                  label: deliveredLabel,
                  onPressed: () => onQuickMark(ServiceEntryStatus.delivered),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickEntryButton(
                  label: missedLabel,
                  onPressed: () => onQuickMark(ServiceEntryStatus.notDelivered),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (service.templateType == ServiceTemplateType.attendance)
            Row(
              children: [
                Expanded(
                  child: _QuickEntryButton(
                    label: 'Half Day',
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
      ),
    );
  }
}

class _QuickEntryButton extends StatelessWidget {
  const _QuickEntryButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;

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
          : FilledButton.tonal(onPressed: onPressed, child: labelWidget),
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

class _ActionSheetGroup extends StatelessWidget {
  const _ActionSheetGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.danger
        : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      onTap: onTap,
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
            : '$quantity${service.unit.isEmpty ? '' : service.unit}';
        final dueLabel = _isCurrentMonth(controller.monthKey)
            ? 'Due till today'
            : 'Monthly Due';
        final currentMonthRemaining =
            settlement?.currentMonthRemainingCents ?? 0;
        final previousBalance = settlement?.previousBalanceRemainingCents ?? 0;
        final advanceApplied = settlement?.advanceUsedCents ?? 0;
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
                        currentMonthRemaining / 100,
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
                      label: 'Advance applied',
                      value: CurrencyFormatter.rupees(advanceApplied / 100),
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
    final parts = monthKey.split('-');
    final year = int.tryParse(parts.first);
    final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
}

class _StatementMetric extends StatelessWidget {
  const _StatementMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.ink,
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
  late ServiceEntryStatus _status;
  late final TextEditingController _quantityController;
  late final TextEditingController _rateController;
  late final TextEditingController _noteController;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final entry = widget.service.entries
        .where((entry) => entry.day == widget.controller.selectedDay)
        .firstOrNull;
    _status = entry?.status ?? ServiceEntryStatus.delivered;
    _quantityController = TextEditingController(
      text: (entry?.quantity ?? widget.service.defaultQuantity).toString(),
    );
    _rateController = TextEditingController(
      text: ((entry?.rateCents ?? widget.service.rateCents) / 100)
          .toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: entry?.note ?? '');
    _unit = entry?.unit.isNotEmpty == true ? entry!.unit : widget.service.unit;
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
    final quantity = double.tryParse(_quantityController.text) ?? 0;
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,3}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            hintText: '1.5',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 112,
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit.isEmpty ? 'Unit' : _unit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: 'L', child: Text('L')),
                            DropdownMenuItem(value: 'Can', child: Text('Can')),
                            DropdownMenuItem(value: 'Day', child: Text('Day')),
                            DropdownMenuItem(
                              value: 'Visit',
                              child: Text('Visit'),
                            ),
                            DropdownMenuItem(
                              value: 'Unit',
                              child: Text('Unit'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _unit = value == 'Unit' ? '' : value ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Rate (${CurrencyFormatter.symbol} / $_unit)',
                    ),
                    onChanged: (_) => setState(() {}),
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
              onPressed: () => widget.controller.saveSelectedEntry(
                status: _status,
                quantity: double.tryParse(_quantityController.text) ?? 0,
                unit: _unit,
                rateCents: ((double.tryParse(_rateController.text) ?? 0) * 100)
                    .round(),
                note: _noteController.text,
              ),
              child: const Center(child: Text('Save Entry')),
            ),
          ),
        ),
      ],
    );
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
    final useTwoRows = options.length > 3;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final selected = option.status == value;
        final width =
            (MediaQuery.sizeOf(context).width -
                (AppSpacing.lg * 4) -
                (useTwoRows ? AppSpacing.sm : AppSpacing.sm * 2)) /
            (useTwoRows ? 2 : 3);
        return SizedBox(
          width: width.clamp(96, 180).toDouble(),
          height: 42,
          child: ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Center(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.background,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.line,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            onSelected: (_) => onChanged(option.status),
          ),
        );
      }).toList(),
    );
  }
}
