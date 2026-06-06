import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/add_advance_bottom_sheet.dart';
import '../widgets/ledger_bottom_nav.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/month_selector.dart';

import 'currency_screen.dart';
import 'home_screen.dart';
import 'payment_history_screen.dart';
import 'service_detail_screen.dart';
import 'settlement_detail_screen.dart';

class LedgerFlowScreen extends StatelessWidget {
  const LedgerFlowScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final overview = controller.overview;
    if (overview == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: HomeLoadingSkeleton(monthKey: controller.monthKey),
        bottomNavigationBar: LedgerBottomNav(
          selectedIndex: _bottomNavIndex,
          onSelected: (index) => _selectBottomNav(index, null),
          onAdd: () => _showAddActions(context, null),
        ),
      );
    }
    final selectedService =
        controller.selectedService ??
        (overview.services.isNotEmpty ? overview.services.first : null);

    return Scaffold(
      appBar: controller.route == LedgerRoute.dashboard
          ? null
          : _appBar(context, selectedService),
      body: switch (controller.route) {
        LedgerRoute.dashboard => HomeScreen(controller: controller),
        LedgerRoute.quickLog => _QuickLogView(controller: controller),
        LedgerRoute.createService => _CreateServiceView(controller: controller),
        LedgerRoute.createServiceReview => _CreateServiceReviewView(
          controller: controller,
        ),
        LedgerRoute.calendar =>
          selectedService == null
              ? const _EmptyLedgerView()
              : ServiceDetailScreen(
                  controller: controller,
                  service: selectedService,
                ),
        LedgerRoute.entry =>
          selectedService == null
              ? const _EmptyLedgerView()
              : EntryView(controller: controller, service: selectedService),
        LedgerRoute.settlementDetail =>
          selectedService == null
              ? const _EmptyLedgerView()
              : SettlementDetailScreen(
                  controller: controller,
                  service: selectedService,
                ),
        LedgerRoute.paymentHistory =>
          selectedService == null
              ? const _EmptyLedgerView()
              : PaymentHistoryScreen(
                  controller: controller,
                  service: selectedService,
                ),
        LedgerRoute.pdfPreview =>
          selectedService == null
              ? const _EmptyLedgerView()
              : _PdfPreview(controller: controller, service: selectedService),
        LedgerRoute.more => _MoreView(controller: controller),
        LedgerRoute.profile => _ProfileView(controller: controller),
        LedgerRoute.currency => CurrencyScreen(controller: controller),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: _showBottomNav
          ? LedgerBottomNav(
              selectedIndex: _bottomNavIndex,
              onSelected: (index) => _selectBottomNav(index, selectedService),
              onAdd: () => _showAddActions(context, selectedService),
            )
          : null,
    );
  }

  bool get _showBottomNav {
    return switch (controller.route) {
      LedgerRoute.dashboard || LedgerRoute.more => true,
      _ => false,
    };
  }

  int get _bottomNavIndex {
    return switch (controller.route) {
      LedgerRoute.more => 1,
      _ => 0,
    };
  }

  void _selectBottomNav(int index, HouseholdService? selectedService) {
    switch (index) {
      case 0:
        controller.goTo(LedgerRoute.dashboard);
      case 1:
        controller.goTo(LedgerRoute.more);
    }
  }

  void _showAddActions(
    BuildContext context,
    HouseholdService? selectedService,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _AddActionTile(
                icon: Icons.event_available_outlined,
                title: 'Quick Log Today',
                subtitle: 'Mark today’s service status quickly',
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.openQuickLog(date: DateTime.now());
                },
              ),
              _AddActionTile(
                icon: Icons.edit_calendar_outlined,
                title: 'Log Past Date',
                subtitle: 'Update service entries for an earlier date',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(now.year - 2),
                    lastDate: now,
                  );
                  if (picked != null) {
                    controller.openQuickLog(date: picked);
                  }
                },
              ),
              _AddActionTile(
                icon: Icons.home_repair_service_outlined,
                title: 'Add Service',
                subtitle: 'Track a new household service',
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.startCreateService();
                },
              ),
              _AddActionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Add Advance',
                subtitle: 'Save an advance for a service',
                isEnabled: controller.overview?.services.isNotEmpty ?? false,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickServiceForAction(
                    context,
                    title: 'Add Advance',
                    onPicked: (service) => _showAdvanceSheet(context, service),
                  );
                },
              ),
              _AddActionTile(
                icon: Icons.description_outlined,
                title: 'Generate Statement',
                subtitle: 'Create a PDF statement for a service',
                isEnabled: controller.overview?.services.isNotEmpty ?? false,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickServiceForAction(
                    context,
                    title: 'Generate Statement',
                    onPicked: (service) {
                      controller.selectedService = service;
                      controller.openPdfPreview(source: PdfSource.bills);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickServiceForAction(
    BuildContext context, {
    required String title,
    required ValueChanged<HouseholdService> onPicked,
  }) {
    final services =
        controller.overview?.services ?? const <HouseholdService>[];
    if (services.isEmpty) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (pickerContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              ...services.map(
                (service) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    serviceIcon(service.icon),
                    color: service.templateType.color,
                  ),
                  title: Text(service.name),
                  subtitle: Text(providerName(service)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(pickerContext);
                    controller.selectedService = service;
                    onPicked(service);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvanceSheet(BuildContext context, HouseholdService service) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAdvanceBottomSheet(
        controller: controller,
        serviceId: service.id,
        serviceName: service.name,
        month: controller.overview?.monthLabel ?? controller.monthKey,
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

  PreferredSizeWidget _appBar(
    BuildContext context,
    HouseholdService? selectedService,
  ) {
    final isCreateService = controller.route == LedgerRoute.createService;
    final isCreateServiceReview =
        controller.route == LedgerRoute.createServiceReview;
    final isServiceDetail = controller.route == LedgerRoute.calendar;
    final isEntryDetail = controller.route == LedgerRoute.entry;
    final isQuickLog = controller.route == LedgerRoute.quickLog;
    final isRootRoute = switch (controller.route) {
      LedgerRoute.dashboard || LedgerRoute.more => true,
      _ => false,
    };
    final showsMonthPicker = switch (controller.route) {
      _ => false,
    };
    return AppBar(
      leading: isRootRoute
          ? null
          : IconButton(
              tooltip: 'Back',
              onPressed: () => controller.goTo(_backRoute()),
              icon: const Icon(Icons.arrow_back),
            ),
      title: Text(
        isCreateService
            ? controller.isEditingService
                  ? 'Edit Service'
                  : 'Add Service'
            : isCreateServiceReview
            ? controller.isEditingService
                  ? 'Review Changes'
                  : 'Service Details'
            : isServiceDetail
            ? selectedService?.name ?? 'Service Details'
            : isEntryDetail
            ? selectedService?.name ?? 'Entry'
            : controller.route == LedgerRoute.settlementDetail
            ? 'Settlement Details'
            : controller.route == LedgerRoute.paymentHistory
            ? 'Payment History'
            : isQuickLog
            ? 'Quick Log'
            : controller.route == LedgerRoute.more
            ? 'More'
            : controller.route == LedgerRoute.profile
            ? 'Profile'
            : controller.route == LedgerRoute.currency
            ? 'Currency'
            : 'Payqure Home',
      ),
      actions: [
        if (showsMonthPicker) MonthSelector(controller: controller),
        if (showsMonthPicker) const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  LedgerRoute _backRoute() {
    return switch (controller.route) {
      LedgerRoute.createServiceReview => LedgerRoute.createService,
      LedgerRoute.createService =>
        controller.isEditingService
            ? LedgerRoute.calendar
            : LedgerRoute.dashboard,
      LedgerRoute.quickLog => LedgerRoute.dashboard,
      LedgerRoute.entry => switch (controller.entrySource) {
        EntrySource.quickLog => LedgerRoute.quickLog,
        EntrySource.calendar => LedgerRoute.calendar,
      },
      LedgerRoute.settlementDetail => LedgerRoute.calendar,
      LedgerRoute.paymentHistory => LedgerRoute.calendar,
      LedgerRoute.pdfPreview => switch (controller.pdfSource) {
        PdfSource.serviceDetail => LedgerRoute.calendar,
        PdfSource.bills => LedgerRoute.dashboard,
      },
      LedgerRoute.profile => LedgerRoute.more,
      LedgerRoute.currency => LedgerRoute.more,
      _ => LedgerRoute.dashboard,
    };
  }
}

class _AddActionTile extends StatelessWidget {
  const _AddActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final foreground = isEnabled ? AppColors.ink : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.background
                : AppColors.background.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.primarySoft
                      : AppColors.line.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? AppColors.primary : AppColors.muted,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLogView extends StatelessWidget {
  const _QuickLogView({required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final overview = controller.overview!;
    final services = overview.services;
    final date = controller.quickLogDate;
    final day = date.day;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            104,
          ),
          children: [
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Date',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatFullDate(date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Change date',
                    onPressed: () => _pickLogDate(context),
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (services.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_business_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No active services',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add a service before logging entries.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: controller.startCreateService,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Service'),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active Services',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _markAllDefaults(context, services, day),
                    child: const Text('Mark All Defaults'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _QuickLogServiceRow(
                    key: ValueKey('quick-${service.id}-$day'),
                    service: service,
                    day: day,
                    onStatusSelected: (status) =>
                        _markStatus(context, service, day, status),
                    onEdit: () {
                      controller.selectedService = service;
                      controller.selectDayForEdit(
                        day,
                        source: EntrySource.quickLog,
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        if (services.isNotEmpty)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.md,
            child: FilledButton.icon(
              onPressed: () => _markAllDefaults(context, services, day),
              icon: const Icon(Icons.done_all_outlined),
              label: const Text('Mark All Defaults'),
            ),
          ),
      ],
    );
  }

  Future<void> _pickLogDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.quickLogDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }
    HapticFeedback.selectionClick();
    await controller.setQuickLogDate(picked);
  }

  void _markStatus(
    BuildContext context,
    HouseholdService service,
    int day,
    ServiceEntryStatus status,
  ) {
    HapticFeedback.lightImpact();
    if (status == ServiceEntryStatus.noEntry) {
      controller.clearQuickEntryForService(service: service, day: day);
      return;
    }
    controller.saveQuickEntryForService(
      service: service,
      day: day,
      status: status,
    );
  }

  void _markAllDefaults(
    BuildContext context,
    List<HouseholdService> services,
    int day,
  ) {
    HapticFeedback.mediumImpact();
    for (final service in services) {
      controller.saveQuickEntryForService(
        service: service,
        day: day,
        status: ServiceEntryStatus.delivered,
      );
    }
  }
}

class _QuickLogServiceRow extends StatefulWidget {
  const _QuickLogServiceRow({
    required this.service,
    required this.day,
    required this.onStatusSelected,
    required this.onEdit,
    super.key,
  });

  final HouseholdService service;
  final int day;
  final ValueChanged<ServiceEntryStatus> onStatusSelected;
  final VoidCallback onEdit;

  @override
  State<_QuickLogServiceRow> createState() => _QuickLogServiceRowState();
}

class _QuickLogServiceRowState extends State<_QuickLogServiceRow> {
  late QuickLogCardProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = QuickLogCardProvider(_entryStatus);
  }

  @override
  void didUpdateWidget(covariant _QuickLogServiceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStatus = _entryStatus;
    if (oldWidget.day != widget.day ||
        oldWidget.service.id != widget.service.id) {
      _provider.dispose();
      _provider = QuickLogCardProvider(nextStatus);
    } else {
      _provider.syncFromStore(nextStatus);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  ServiceEntryStatus get _entryStatus {
    final entry = widget.service.entries
        .where((entry) => entry.day == widget.day)
        .firstOrNull;
    return entry?.status ?? ServiceEntryStatus.noEntry;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        final status = _provider.status;
        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.service.templateType.color.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      serviceIcon(widget.service.icon),
                      color: widget.service.templateType.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _defaultSummary(widget.service),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: status == ServiceEntryStatus.noEntry
                        ? const SizedBox(width: 24, height: 24)
                        : Icon(
                            Icons.check_circle,
                            key: ValueKey(status),
                            color: _statusColor(status),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              StatusSelector(
                options: _statusOptions(widget.service),
                value: status,
                onChanged: (nextStatus) {
                  HapticFeedback.selectionClick();
                  _provider.select(nextStatus);
                  widget.onStatusSelected(nextStatus);
                },
              ),
              SizedBox(
                height: 32,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onEdit,
                    child: const Text('Edit'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<StatusOption> _statusOptions(HouseholdService service) {
    if (service.templateType == ServiceTemplateType.attendance) {
      return const [
        StatusOption(ServiceEntryStatus.noEntry, 'Not Logged'),
        StatusOption(ServiceEntryStatus.delivered, 'Present'),
        StatusOption(ServiceEntryStatus.notDelivered, 'Absent'),
        StatusOption(ServiceEntryStatus.halfDay, 'Half Day'),
      ];
    }
    return const [
      StatusOption(ServiceEntryStatus.noEntry, 'Not Logged'),
      StatusOption(ServiceEntryStatus.delivered, 'Delivered'),
      StatusOption(ServiceEntryStatus.notDelivered, 'Not Delivered'),
    ];
  }

  String _defaultSummary(HouseholdService service) {
    if (service.templateType == ServiceTemplateType.attendance) {
      return '${CurrencyFormatter.rupees(service.rateCents / 100)}/day';
    }
    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      return 'Delivered';
    }
    final quantity = service.defaultQuantity.toStringAsFixed(
      service.defaultQuantity.truncateToDouble() == service.defaultQuantity
          ? 0
          : 1,
    );
    return '$quantity${service.unit} @ ${CurrencyFormatter.rupees(service.rateCents / 100)}';
  }
}

class QuickLogCardProvider extends ChangeNotifier {
  QuickLogCardProvider(this._status);

  ServiceEntryStatus _status;

  ServiceEntryStatus get status => _status;

  void select(ServiceEntryStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    notifyListeners();
  }

  void syncFromStore(ServiceEntryStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    notifyListeners();
  }
}

class StatusOption {
  const StatusOption(this.status, this.label);

  final ServiceEntryStatus status;
  final String label;
}

class StatusSelector extends StatelessWidget {
  const StatusSelector({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<StatusOption> options;
  final ServiceEntryStatus value;
  final ValueChanged<ServiceEntryStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final selected = option.status == value;
        final color = _statusColor(option.status);
        return InkWell(
          onTap: () => onChanged(option.status),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.14)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: selected ? color : AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  option.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? color : AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

Color _statusColor(ServiceEntryStatus status) {
  return switch (status) {
    ServiceEntryStatus.delivered => AppColors.success,
    ServiceEntryStatus.notDelivered => AppColors.danger,
    ServiceEntryStatus.rateChanged => AppColors.info,
    ServiceEntryStatus.halfDay => AppColors.warning,
    ServiceEntryStatus.noEntry => AppColors.muted,
  };
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview({required this.controller, required this.service});

  final LedgerController controller;
  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyBill?>(
      future: controller.loadSelectedBill(),
      builder: (context, snapshot) {
        final bill = snapshot.data;
        if (bill == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return PdfPreview(
          build: (_) => controller.buildSelectedPdf().then((bytes) => bytes!),
          canChangeOrientation: false,
          canChangePageFormat: false,
          initialPageFormat: PdfPageFormat.a4,
        );
      },
    );
  }
}

class _MoreView extends StatelessWidget {
  const _MoreView({required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _MoreSection(
          title: 'Account',
          children: [
            _MoreTile(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () => controller.goTo(LedgerRoute.profile),
            ),
            _MoreTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => controller.goTo(LedgerRoute.forgotPassword),
            ),
          ],
        ),
        _MoreSection(
          title: 'Records',
          children: const [
            _MoreTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payment History',
            ),
            _MoreTile(icon: Icons.history_outlined, title: 'Advance History'),
            _MoreTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Generated Statements',
            ),
          ],
        ),
        _MoreSection(
          title: 'Preferences',
          children: [
            _MoreTile(
              icon: Icons.attach_money_outlined,
              title:
                  'Currency (${controller.selectedCurrency.code} ${controller.selectedCurrency.symbol})',
              onTap: () => controller.goTo(LedgerRoute.currency),
            ),
            const _MoreTile(icon: Icons.palette_outlined, title: 'Theme'),
            const _MoreTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
            ),
            const _MoreTile(icon: Icons.sync_outlined, title: 'Sync Status'),
          ],
        ),
        _MoreSection(
          title: 'Support',
          children: const [
            _MoreTile(
              icon: Icons.support_agent_outlined,
              title: 'Help & Support',
            ),
            _MoreTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
            ),
            _MoreTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
            ),
          ],
        ),
        _MoreSection(
          title: 'Danger Zone',
          children: [
            _MoreTile(
              icon: Icons.logout_outlined,
              title: 'Logout',
              destructive: true,
              onTap: controller.signOut,
            ),
          ],
        ),
      ],
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: destructive ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: destructive
          ? null
          : const Icon(Icons.chevron_right, color: AppColors.muted),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView({required this.controller});

  final LedgerController controller;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      (profile?.name.isNotEmpty == true
                              ? profile!.name[0]
                              : 'P')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? 'Payqure User',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DetailRow(label: 'Phone', value: profile?.phone ?? ''),
              DetailRow(
                label: 'Email status',
                value: profile?.emailVerified == true
                    ? 'Email verified'
                    : 'Email verification pending',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Full name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Phone', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(hintText: '+919999999999'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp('[^0-9]'), '');
                  return digits.length >= 10 ? null : 'Enter a valid phone';
                },
              ),
            ],
          ),
        ),
        if (widget.controller.successMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.controller.successMessage!,
            style: const TextStyle(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.controller.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.controller.errorMessage!,
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            widget.controller.updateProfile(
              name: _nameController.text,
              phone: _phoneController.text,
            );
          },
          child: const Text('Save Profile'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => widget.controller.goTo(LedgerRoute.forgotPassword),
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}

class _CreateServiceView extends StatefulWidget {
  const _CreateServiceView({required this.controller});

  final LedgerController controller;

  @override
  State<_CreateServiceView> createState() => _CreateServiceViewState();
}

class _CreateServiceViewState extends State<_CreateServiceView> {
  final _formKey = GlobalKey<FormState>();
  final providerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _serviceTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _amountController = TextEditingController();
  ServiceTemplateType _templateType = ServiceTemplateType.quantity;
  int _remindBeforeMinutes = 30;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.addServiceDraft;
    if (draft == null) {
      return;
    }
    providerNameController.text = draft.providerName;
    _contactController.text = draft.contactNumber;
    _serviceTimeController.text = draft.serviceTime;
    _startDate = draft.startDate;
    _startDateController.text = _formatDate(draft.startDate);
    _serviceNameController.text = draft.serviceName;
    _amountController.text = draft.amount.toStringAsFixed(0);
    _templateType = draft.templateType;
    _remindBeforeMinutes = draft.remindBeforeMinutes;
  }

  @override
  void dispose() {
    providerNameController.dispose();
    _contactController.dispose();
    _serviceTimeController.dispose();
    _startDateController.dispose();
    _serviceNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: providerNameController,
                decoration: const InputDecoration(
                  labelText: 'Service Provider Name',
                ),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _serviceTimeController,
                readOnly: true,
                onTap: _pickServiceTime,
                decoration: const InputDecoration(
                  labelText: 'Time of Service Provider',
                  suffixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                initialValue: _remindBeforeMinutes,
                decoration: const InputDecoration(
                  labelText: 'Time Before To Remind For Service',
                ),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                  DropdownMenuItem(value: 60, child: Text('1 hour before')),
                  DropdownMenuItem(value: 120, child: Text('2 hours before')),
                ],
                onChanged: (value) =>
                    setState(() => _remindBeforeMinutes = value ?? 30),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _startDateController,
                readOnly: true,
                onTap: _pickStartDate,
                decoration: const InputDecoration(
                  labelText: 'Service Start Date',
                  suffixIcon: Icon(Icons.event_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _serviceNameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ServiceTemplateType>(
                initialValue: _templateType,
                decoration: const InputDecoration(labelText: 'Service Type'),
                items: ServiceTemplateType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: widget.controller.isEditingService
                    ? null
                    : (value) => setState(
                        () => _templateType = value ?? _templateType,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (${CurrencyFormatter.symbol})',
                ),
                validator: _amount,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.arrow_forward),
          label: Text(
            widget.controller.isEditingService
                ? 'Review Changes'
                : 'Add Service',
          ),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _amount(String? value) {
    final amount = double.tryParse(value ?? '');
    return amount == null || amount < 0 ? 'Enter a valid amount' : null;
  }

  Future<void> _pickServiceTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() => _serviceTimeController.text = picked.format(context));
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _startDate = picked;
      _startDateController.text = _formatDate(picked);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    widget.controller.reviewAddService(
      AddServiceDraft(
        providerName: providerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        serviceTime: _serviceTimeController.text.trim(),
        remindBeforeMinutes: _remindBeforeMinutes,
        startDate: _startDate!,
        serviceName: _serviceNameController.text.trim(),
        templateType: _templateType,
        amount: double.tryParse(_amountController.text) ?? 0,
      ),
    );
  }
}

class _CreateServiceReviewView extends StatelessWidget {
  const _CreateServiceReviewView({required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.addServiceDraft;
    if (draft == null) {
      return Center(
        child: FilledButton(
          onPressed: controller.startCreateService,
          child: const Text('Back to Add Service'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            children: [
              DetailRow(label: 'Service Name', value: draft.serviceName),
              DetailRow(label: 'Provider', value: draft.providerName),
              DetailRow(label: 'Contact', value: draft.contactNumber),
              DetailRow(label: 'Service Time', value: draft.serviceTime),
              DetailRow(
                label: 'Reminder',
                value: '${draft.remindBeforeMinutes} minutes before',
              ),
              DetailRow(label: 'Service Type', value: draft.templateType.label),
              DetailRow(
                label: 'Amount',
                value: CurrencyFormatter.rupees(draft.amount),
              ),
              DetailRow(
                label: 'Start Date',
                value:
                    '${draft.startDate.day.toString().padLeft(2, '0')}/${draft.startDate.month.toString().padLeft(2, '0')}/${draft.startDate.year}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: controller.saveDraftService,
          child: Text(controller.isEditingService ? 'Save Changes' : 'Done'),
        ),
      ],
    );
  }
}

class _EmptyLedgerView extends StatelessWidget {
  const _EmptyLedgerView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No service selected'));
  }
}
