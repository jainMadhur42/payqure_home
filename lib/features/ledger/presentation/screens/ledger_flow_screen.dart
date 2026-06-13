import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../legal/presentation/legal_screens.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/service_template_catalog.dart';
import '../controllers/ledger_controller.dart';
import '../models/add_service_draft.dart';
import '../widgets/ledger_bottom_nav.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/month_selector.dart';
import '../widgets/quick_entry_actions.dart';
import '../widgets/service_icon.dart';

import 'currency_screen.dart';
import 'contacts_screen.dart';
import 'global_history_screen.dart';
import 'home_screen.dart';
import 'manage_service_screen.dart';
import 'payment_history_screen.dart';
import 'service_detail_screen.dart';
import 'service_contribution_screen.dart';
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
          onAdd: controller.startCreateService,
        ),
      );
    }
    final selectedService =
        controller.selectedService ??
        (overview.services.isNotEmpty ? overview.services.first : null);

    final scaffold = Scaffold(
      appBar: controller.route == LedgerRoute.dashboard
          ? null
          : _appBar(context, selectedService),
      body: switch (controller.route) {
        LedgerRoute.dashboard => HomeScreen(controller: controller),
        LedgerRoute.contributionStats => ServiceContributionScreen(
          controller: controller,
        ),
        LedgerRoute.quickLog => _QuickLogView(controller: controller),
        LedgerRoute.createServiceTemplate => ServiceTemplatePickerScreen(
          selectedTemplateId:
              controller.addServiceDraft?.serviceTemplateName ?? '',
          onSelected: controller.selectServiceTemplate,
          embedded: true,
        ),
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
        LedgerRoute.manageService =>
          selectedService == null
              ? const _EmptyLedgerView()
              : ManageServiceScreen(
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
        LedgerRoute.serviceAdvanceHistory =>
          selectedService == null
              ? const _EmptyLedgerView()
              : GlobalHistoryScreen(
                  controller: controller,
                  type: ServiceHistoryType.advance,
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
        LedgerRoute.more => _SettingsView(controller: controller),
        LedgerRoute.profile => _ProfileView(controller: controller),
        LedgerRoute.currency => CurrencyScreen(controller: controller),
        LedgerRoute.theme => ThemeScreen(controller: controller),
        LedgerRoute.privacyPolicy => const PrivacyPolicyView(),
        LedgerRoute.termsDisclaimer => const TermsDisclaimerView(),
        LedgerRoute.deleteMyData => DeleteMyDataView(
          registeredIdentifier: controller.profile?.email.isNotEmpty == true
              ? controller.profile!.email
              : controller.profile?.phone ?? '',
        ),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: _showBottomNav
          ? LedgerBottomNav(
              selectedIndex: _bottomNavIndex,
              onSelected: _selectBottomNav,
              onAdd: controller.startCreateService,
            )
          : null,
    );
    final isRootRoute = controller.route == LedgerRoute.dashboard;
    return PopScope(
      canPop: isRootRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.goBackTo(_backRoute());
        }
      },
      child: scaffold,
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

  PreferredSizeWidget _appBar(
    BuildContext context,
    HouseholdService? selectedService,
  ) {
    final isCreateService = controller.route == LedgerRoute.createService;
    final isServiceTemplatePicker =
        controller.route == LedgerRoute.createServiceTemplate;
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
              onPressed: () => controller.goBackTo(_backRoute()),
              icon: const Icon(Icons.arrow_back),
            ),
      title: Text(
        isServiceTemplatePicker
            ? 'Select Service'
            : isCreateService
            ? controller.isEditingService
                  ? 'Edit Service'
                  : 'Add Service'
            : isCreateServiceReview
            ? controller.isEditingService
                  ? 'Review Changes'
                  : 'Service Details'
            : isServiceDetail
            ? selectedService?.name ?? 'Service Details'
            : controller.route == LedgerRoute.manageService
            ? 'Manage Service'
            : isEntryDetail
            ? selectedService?.name ?? 'Entry'
            : controller.route == LedgerRoute.settlementDetail
            ? controller.serviceActionReturnRoute == LedgerRoute.manageService
                  ? 'Billing Summary'
                  : 'Settlement Details'
            : controller.route == LedgerRoute.paymentHistory
            ? controller.serviceActionReturnRoute == LedgerRoute.manageService
                  ? 'Transaction History'
                  : 'Payment History'
            : controller.route == LedgerRoute.globalPaymentHistory
            ? 'Payment History'
            : controller.route == LedgerRoute.contributionStats
            ? 'Spending Stats'
            : controller.route == LedgerRoute.advanceHistory
            ? 'Advance History'
            : controller.route == LedgerRoute.serviceAdvanceHistory
            ? '${selectedService?.name ?? 'Service'} Advances'
            : isQuickLog
            ? 'Quick Log'
            : controller.route == LedgerRoute.more
            ? 'Settings'
            : controller.route == LedgerRoute.contacts
            ? 'Contacts (${ContactsScreen.contactCount(controller.overview?.services ?? const [])})'
            : controller.route == LedgerRoute.profile
            ? 'Profile'
            : controller.route == LedgerRoute.currency
            ? 'Currency'
            : controller.route == LedgerRoute.theme
            ? 'Theme'
            : controller.route == LedgerRoute.privacyPolicy
            ? 'Privacy Policy'
            : controller.route == LedgerRoute.termsDisclaimer
            ? 'Terms & Disclaimer'
            : controller.route == LedgerRoute.deleteMyData
            ? 'Delete My Data'
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
            ? controller.serviceEditReturnRoute
            : LedgerRoute.createServiceTemplate,
      LedgerRoute.createServiceTemplate => LedgerRoute.dashboard,
      LedgerRoute.quickLog => LedgerRoute.dashboard,
      LedgerRoute.contributionStats => LedgerRoute.dashboard,
      LedgerRoute.entry => switch (controller.entrySource) {
        EntrySource.quickLog => LedgerRoute.quickLog,
        EntrySource.calendar => LedgerRoute.calendar,
      },
      LedgerRoute.manageService => LedgerRoute.calendar,
      LedgerRoute.settlementDetail ||
      LedgerRoute.paymentHistory ||
      LedgerRoute.serviceAdvanceHistory => controller.serviceActionReturnRoute,
      LedgerRoute.globalPaymentHistory ||
      LedgerRoute.advanceHistory ||
      LedgerRoute.theme => LedgerRoute.more,
      LedgerRoute.contacts => LedgerRoute.more,
      LedgerRoute.privacyPolicy ||
      LedgerRoute.termsDisclaimer ||
      LedgerRoute.deleteMyData => LedgerRoute.profile,
      LedgerRoute.pdfPreview => switch (controller.pdfSource) {
        PdfSource.serviceDetail => LedgerRoute.calendar,
        PdfSource.manageService => LedgerRoute.manageService,
        PdfSource.bills => LedgerRoute.dashboard,
      },
      LedgerRoute.profile => LedgerRoute.dashboard,
      LedgerRoute.currency => LedgerRoute.more,
      _ => LedgerRoute.dashboard,
    };
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
              Text(
                'Active Services',
                style: Theme.of(context).textTheme.titleMedium,
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
    controller.saveDefaultsForAllServices(services: services, day: day);
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
              QuickEntryActionGrid(
                service: widget.service,
                selectedStatus: status,
                onQuickMark: (nextStatus) {
                  HapticFeedback.selectionClick();
                  _provider.select(nextStatus);
                  widget.onStatusSelected(nextStatus);
                },
                onCustomize: widget.onEdit,
              ),
            ],
          ),
        );
      },
    );
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

Color _statusColor(ServiceEntryStatus status) {
  return switch (status) {
    ServiceEntryStatus.delivered => AppColors.success,
    ServiceEntryStatus.notDelivered => AppColors.danger,
    ServiceEntryStatus.rateChanged => AppColors.info,
    ServiceEntryStatus.halfDay => AppColors.warning,
    ServiceEntryStatus.noEntry => AppColors.muted,
  };
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({required this.controller, required this.service});

  final LedgerController controller;
  final HouseholdService service;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  late Future<Uint8List?> _statementBytes;
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = widget.controller.monthKey;
    _statementBytes = widget.controller.buildSelectedPdf();
  }

  @override
  void didUpdateWidget(covariant _PdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextMonthKey = widget.controller.monthKey;
    if (oldWidget.service.id != widget.service.id ||
        _monthKey != nextMonthKey) {
      _monthKey = nextMonthKey;
      _statementBytes = widget.controller.buildSelectedPdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _statementBytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not generate PDF. Please try again.'),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return PdfPreview(
          build: (_) async => bytes,
          canChangeOrientation: false,
          canChangePageFormat: false,
          initialPageFormat: PdfPageFormat.a4,
        );
      },
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
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
        _AppVersionFooter(versionLabel: controller.appVersionLabel),
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

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter({required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Text(
            'Payqure Home',
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            versionLabel,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        ],
      ),
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
    final color = destructive
        ? AppColors.danger
        : Theme.of(context).colorScheme.onSurface;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
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
      ),
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
                key: const ValueKey('profile-name'),
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Full name'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Phone', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const ValueKey('profile-phone'),
                controller: _phoneController,
                decoration: const InputDecoration(hintText: '+919999999999'),
                keyboardType: TextInputType.phone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
        const SizedBox(height: AppSpacing.xl),
        _MoreSection(
          title: 'Legal',
          children: [
            _MoreTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => widget.controller.goTo(LedgerRoute.privacyPolicy),
            ),
            _MoreTile(
              icon: Icons.gavel_outlined,
              title: 'Terms & Disclaimer',
              onTap: () => widget.controller.goTo(LedgerRoute.termsDisclaimer),
            ),
            _MoreTile(
              icon: Icons.delete_outline,
              title: 'Delete My Data',
              destructive: true,
              onTap: () => widget.controller.goTo(LedgerRoute.deleteMyData),
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
              onTap: widget.controller.signOut,
            ),
          ],
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
                key: const ValueKey('service-provider-name'),
                controller: providerNameController,
                decoration: const InputDecoration(
                  labelText: 'Service Provider Name',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const ValueKey('service-provider-contact'),
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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

    void editDraft() => controller.goBackTo(LedgerRoute.createService);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      key: const ValueKey('service-review-scroll-view'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl + bottomInset,
      ),
      children: [
        Text(
          controller.isEditingService
              ? 'Please review the updated details before saving'
              : 'Please review the service details before saving',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ServiceReviewHero(draft: draft),
        const SizedBox(height: AppSpacing.lg),
        _ReviewSection(
          icon: Icons.person_outline_rounded,
          title: 'Provider Details',
          children: [
            _ReviewDetailTile(
              icon: Icons.person_outline_rounded,
              label: 'Provider Name',
              value: draft.providerName,
              onTap: editDraft,
            ),
            _ReviewDetailTile(
              icon: Icons.phone_outlined,
              label: 'Contact Number',
              value: draft.contactNumber,
              onTap: editDraft,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewSection(
          icon: Icons.schedule_outlined,
          title: 'Schedule & Reminder',
          children: [
            _ReviewDetailTile(
              icon: Icons.schedule_outlined,
              label: 'Service Time',
              value: draft.serviceTime.isEmpty ? 'Not set' : draft.serviceTime,
              onTap: editDraft,
            ),
            _ReviewDetailTile(
              icon: Icons.notifications_none_rounded,
              label: 'Reminder',
              value: draft.remindBeforeMinutes <= 0
                  ? 'No reminder'
                  : '${draft.remindBeforeMinutes} minutes before',
              valueAccent: draft.remindBeforeMinutes > 0,
              onTap: editDraft,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewSection(
          icon: Icons.sell_outlined,
          title: 'Pricing Details',
          children: [_ReviewPricingCard(draft: draft)],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewSection(
          icon: Icons.calendar_month_outlined,
          title: 'Service Dates',
          children: [
            _ReviewDetailTile(
              icon: Icons.calendar_month_outlined,
              label: 'Start Date',
              value: fullDateLabel(
                draft.startDate.day,
                monthKeyForDate(draft.startDate),
              ),
              onTap: editDraft,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  controller.isEditingService
                      ? 'Review everything before updating your service.'
                      : 'Review everything before creating your service.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: controller.isLoading
                ? null
                : controller.saveDraftService,
            icon: const Icon(Icons.save_outlined, size: 20),
            label: Text(
              controller.isEditingService ? 'Save Changes' : 'Create Service',
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceReviewHero extends StatelessWidget {
  const _ServiceReviewHero({required this.draft});

  final AddServiceDraft draft;

  @override
  Widget build(BuildContext context) {
    final accent = draft.templateType.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        children: [
          ServiceIcon(
            icon: draft.serviceIcon,
            color: accent,
            serviceName: draft.serviceName,
            templateType: draft.templateType,
            size: 72,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text.rich(
                  TextSpan(
                    text: 'Provider: ',
                    children: [
                      TextSpan(
                        text: draft.providerName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    draft.templateType.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    color: Theme.of(context).dividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewDetailTile extends StatelessWidget {
  const _ReviewDetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueAccent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool valueAccent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                icon,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: valueAccent
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPricingCard extends StatelessWidget {
  const _ReviewPricingCard({required this.draft});

  final AddServiceDraft draft;

  @override
  Widget build(BuildContext context) {
    final metrics = switch (draft.templateType) {
      ServiceTemplateType.quantity => [
        _ReviewMetric(
          icon: Icons.inventory_2_outlined,
          label: 'Unit',
          value: draft.unit,
          color: AppColors.success,
        ),
        _ReviewMetric(
          icon: Icons.balance_outlined,
          label: 'Default Quantity',
          value: _formatQuantity(draft.defaultQuantity),
          color: AppColors.success,
        ),
        _ReviewMetric(
          icon: Icons.currency_rupee,
          label: 'Unit Price',
          value: CurrencyFormatter.rupees(draft.amount),
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
      ServiceTemplateType.attendance => [
        _ReviewMetric(
          icon: Icons.calendar_today_outlined,
          label: 'Unit',
          value: 'Day',
          color: AppColors.warning,
        ),
        _ReviewMetric(
          icon: Icons.currency_rupee,
          label: 'Daily Wage',
          value: CurrencyFormatter.rupees(draft.amount),
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
      ServiceTemplateType.fixedMonthly => [
        _ReviewMetric(
          icon: Icons.calendar_month_outlined,
          label: 'Unit',
          value: 'Month',
          color: AppColors.info,
        ),
        _ReviewMetric(
          icon: Icons.currency_rupee,
          label: 'Monthly Amount',
          value: CurrencyFormatter.rupees(draft.amount),
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(child: metrics[index]),
            if (index < metrics.length - 1)
              SizedBox(
                height: 72,
                child: VerticalDivider(
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _ReviewMetric extends StatelessWidget {
  const _ReviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
