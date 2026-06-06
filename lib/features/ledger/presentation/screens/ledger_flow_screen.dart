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
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/service_template_catalog.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_bottom_nav.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/month_selector.dart';

import 'currency_screen.dart';
import 'contacts_screen.dart';
import 'global_history_screen.dart';
import 'home_screen.dart';
import 'payment_history_screen.dart';
import 'service_detail_screen.dart';
import 'service_template_picker_screen.dart';
import 'settlement_detail_screen.dart';
import 'theme_screen.dart';
import 'unit_picker_screen.dart';

class LedgerFlowScreen extends StatelessWidget {
  const LedgerFlowScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final overview = controller.overview;
    if (overview == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: HomeLoadingSkeleton(monthKey: controller.monthKey),
        bottomNavigationBar: LedgerBottomNav(
          selectedIndex: _bottomNavIndex,
          onSelected: _selectBottomNav,
          onAdd: () => _showAddActions(context),
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
        LedgerRoute.globalPaymentHistory => GlobalHistoryScreen(
          controller: controller,
          type: ServiceHistoryType.payment,
        ),
        LedgerRoute.advanceHistory => GlobalHistoryScreen(
          controller: controller,
          type: ServiceHistoryType.advance,
        ),
        LedgerRoute.pdfPreview =>
          selectedService == null
              ? const _EmptyLedgerView()
              : _PdfPreview(controller: controller, service: selectedService),
        LedgerRoute.contacts => ContactsScreen(services: overview.services),
        LedgerRoute.more => _MoreView(controller: controller),
        LedgerRoute.profile => _ProfileView(controller: controller),
        LedgerRoute.currency => CurrencyScreen(controller: controller),
        LedgerRoute.theme => ThemeScreen(controller: controller),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: _showBottomNav
          ? LedgerBottomNav(
              selectedIndex: _bottomNavIndex,
              onSelected: _selectBottomNav,
              onAdd: () => _showAddActions(context),
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

  void _selectBottomNav(int index) {
    switch (index) {
      case 0:
        controller.goTo(LedgerRoute.dashboard);
      case 1:
        controller.goTo(LedgerRoute.more);
    }
  }

  void _showAddActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.52,
        minChildSize: 0.40,
        maxChildSize: 0.72,
        expand: false,
        builder: (context, scrollController) => Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
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
                  ],
                ),
              ),
            ],
          ),
        ),
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
            : controller.route == LedgerRoute.globalPaymentHistory
            ? 'Payment History'
            : controller.route == LedgerRoute.advanceHistory
            ? 'Advance History'
            : isQuickLog
            ? 'Quick Log'
            : controller.route == LedgerRoute.more
            ? 'More'
            : controller.route == LedgerRoute.contacts
            ? 'Contacts (${ContactsScreen.contactCount(controller.overview?.services ?? const [])})'
            : controller.route == LedgerRoute.profile
            ? 'Profile'
            : controller.route == LedgerRoute.currency
            ? 'Currency'
            : controller.route == LedgerRoute.theme
            ? 'Theme'
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
      LedgerRoute.globalPaymentHistory ||
      LedgerRoute.advanceHistory ||
      LedgerRoute.theme => LedgerRoute.more,
      LedgerRoute.contacts => LedgerRoute.more,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
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
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
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
          children: [
            _MoreTile(
              icon: Icons.contacts_outlined,
              title:
                  'Contacts (${ContactsScreen.contactCount(controller.overview?.services ?? const [])})',
              onTap: () => controller.goTo(LedgerRoute.contacts),
            ),
            _MoreTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payment History',
              onTap: () => controller.goTo(LedgerRoute.globalPaymentHistory),
            ),
            _MoreTile(
              icon: Icons.history_outlined,
              title: 'Advance History',
              onTap: () => controller.goTo(LedgerRoute.advanceHistory),
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
            _MoreTile(
              icon: Icons.palette_outlined,
              title: 'Theme (${_themeLabel(controller.selectedThemeMode)})',
              onTap: () => controller.goTo(LedgerRoute.theme),
            ),
          ],
        ),
        _MoreSection(
          title: 'Support',
          children: const [
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

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
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
    final color = destructive
        ? AppColors.danger
        : Theme.of(context).colorScheme.onSurface;
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
          : Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CreateServiceViewState extends State<_CreateServiceView> {
  final _formKey = GlobalKey<FormState>();
  final providerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _serviceTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _amountController = TextEditingController();
  ServiceTemplateDefinition? _selectedTemplate;
  String? _selectedUnit;
  int _remindBeforeMinutes = 0;
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
    _quantityController.text = draft.defaultQuantity.toStringAsFixed(
      draft.defaultQuantity.truncateToDouble() == draft.defaultQuantity ? 0 : 1,
    );
    _amountController.text = draft.amount.toStringAsFixed(0);
    _selectedTemplate = ServiceTemplateCatalog.byId(draft.serviceTemplateName);
    _selectedUnit = draft.unit;
    _remindBeforeMinutes = draft.remindBeforeMinutes;
  }

  @override
  void dispose() {
    providerNameController.dispose();
    _contactController.dispose();
    _serviceTimeController.dispose();
    _startDateController.dispose();
    _serviceNameController.dispose();
    _quantityController.dispose();
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
              InkWell(
                onTap: widget.controller.isEditingService
                    ? null
                    : _pickServiceTemplate,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    suffixIcon: Icon(Icons.chevron_right),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedTemplate?.emoji ?? '＋',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _selectedTemplate?.title ?? 'Choose service',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: _selectedTemplate == null
                                    ? AppColors.muted
                                    : AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedTemplate?.isCustom == true) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _serviceNameController,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                  validator: _required,
                ),
              ],
              if (_selectedTemplate?.templateType ==
                  ServiceTemplateType.quantity) ...[
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: _pickUnit,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      suffixIcon: Icon(Icons.chevron_right),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.straighten_rounded,
                          color: AppColors.primary,
                          size: 21,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _selectedUnit ?? 'Choose unit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: _selectedUnit == null
                                      ? AppColors.muted
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
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
                    labelText: 'Default Quantity',
                  ),
                  validator: _quantity,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: _amountLabel),
                validator: _amount,
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
              const SizedBox(height: AppSpacing.xl),
              const _FormSectionHeader(
                title: 'Reminder',
                subtitle:
                    'Optional. Set a service time and choose when to be reminded.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _serviceTimeController,
                readOnly: true,
                onTap: _pickServiceTime,
                decoration: InputDecoration(
                  labelText: 'Time of Service',
                  hintText: 'Not set',
                  suffixIcon: _serviceTimeController.text.isEmpty
                      ? const Icon(Icons.schedule_outlined)
                      : IconButton(
                          tooltip: 'Clear service time',
                          onPressed: () {
                            setState(() {
                              _serviceTimeController.clear();
                              _remindBeforeMinutes = 0;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                key: ValueKey(_remindBeforeMinutes),
                initialValue: _remindBeforeMinutes,
                decoration: const InputDecoration(labelText: 'Remind me'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('No reminder')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                  DropdownMenuItem(value: 60, child: Text('1 hour before')),
                  DropdownMenuItem(value: 120, child: Text('2 hours before')),
                ],
                onChanged: _serviceTimeController.text.isEmpty
                    ? null
                    : (value) =>
                          setState(() => _remindBeforeMinutes = value ?? 0),
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

  String? _quantity(String? value) {
    final quantity = double.tryParse(value ?? '');
    return quantity == null || quantity <= 0 ? 'Enter a valid quantity' : null;
  }

  String get _amountLabel {
    final template = _selectedTemplate;
    if (template?.templateType == ServiceTemplateType.attendance) {
      return 'Daily Wage (${CurrencyFormatter.symbol})';
    }
    if (template?.templateType == ServiceTemplateType.fixedMonthly) {
      return 'Monthly Amount (${CurrencyFormatter.symbol})';
    }
    final unit = _selectedUnit ?? 'Unit';
    return 'Price Per $unit (${CurrencyFormatter.symbol})';
  }

  List<String> get _availableUnits {
    final units = [...?_selectedTemplate?.units];
    final selectedUnit = _selectedUnit;
    if (selectedUnit != null &&
        selectedUnit.isNotEmpty &&
        !units.contains(selectedUnit)) {
      units.add(selectedUnit);
    }
    return units;
  }

  Future<void> _pickServiceTemplate() async {
    final selected = await Navigator.of(context)
        .push<ServiceTemplateDefinition>(
          MaterialPageRoute(
            builder: (_) => ServiceTemplatePickerScreen(
              selectedTemplateId: _selectedTemplate?.id ?? '',
            ),
          ),
        );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTemplate = selected;
      _selectedUnit = selected.defaultUnit;
      _quantityController.text = selected.defaultQuantity.toStringAsFixed(
        selected.defaultQuantity.truncateToDouble() == selected.defaultQuantity
            ? 0
            : 1,
      );
      if (!selected.isCustom) {
        _serviceNameController.text = selected.title;
      } else {
        _serviceNameController.clear();
      }
    });
  }

  Future<void> _pickUnit() async {
    final units = _availableUnits;
    if (units.isEmpty) {
      return;
    }
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => UnitPickerScreen(
          units: units,
          selectedUnit: _selectedUnit,
          serviceName: _selectedTemplate?.title ?? '',
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _selectedUnit = selected);
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
    final template = _selectedTemplate;
    if (template == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a service first.')));
      return;
    }
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
        serviceName: template.isCustom
            ? _serviceNameController.text.trim()
            : template.title,
        serviceTemplateName: template.id,
        serviceIcon: template.iconIdentifier,
        templateType: template.templateType,
        unit: template.templateType == ServiceTemplateType.quantity
            ? (_selectedUnit ?? template.defaultUnit)
            : template.defaultUnit,
        defaultQuantity: template.templateType == ServiceTemplateType.quantity
            ? double.tryParse(_quantityController.text) ??
                  template.defaultQuantity
            : 1,
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
              DetailRow(
                label: 'Service Time',
                value: draft.serviceTime.isEmpty
                    ? 'Not set'
                    : draft.serviceTime,
              ),
              DetailRow(
                label: 'Reminder',
                value: draft.remindBeforeMinutes <= 0
                    ? 'Not set'
                    : '${draft.remindBeforeMinutes} minutes before',
              ),
              if (draft.templateType == ServiceTemplateType.quantity) ...[
                DetailRow(label: 'Unit', value: draft.unit),
                DetailRow(
                  label: 'Default Quantity',
                  value: draft.defaultQuantity.toStringAsFixed(
                    draft.defaultQuantity.truncateToDouble() ==
                            draft.defaultQuantity
                        ? 0
                        : 1,
                  ),
                ),
              ],
              DetailRow(
                label: switch (draft.templateType) {
                  ServiceTemplateType.quantity => 'Unit Price',
                  ServiceTemplateType.attendance => 'Daily Wage',
                  ServiceTemplateType.fixedMonthly => 'Monthly Amount',
                },
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
