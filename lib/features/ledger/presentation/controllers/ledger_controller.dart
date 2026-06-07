import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/utils/error_message_mapper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../legal/domain/legal_content.dart';
import '../../data/services/pdf_statement_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/ledger_overview.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/payment_settlement_preview.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/entry_amount_calculator.dart';
import '../../domain/services/home_summary_builder.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../../domain/usecases/ledger_calculation_usecases.dart';
import '../models/add_service_draft.dart';
import 'entry_operations_controller.dart';
import 'month_data_controller.dart';
import 'payment_operations_controller.dart';
import 'session_controller.dart';

enum EntrySource { quickLog, calendar }

enum PdfSource { serviceDetail, bills }

class LedgerController extends ChangeNotifier {
  static const _currencyPreferenceKey = 'currency_code';
  static const _themePreferenceKey = 'theme_mode';
  static const _onboardingPreferenceKey = 'has_seen_onboarding';

  LedgerController({
    required AuthRepository authRepository,
    required LedgerRepository ledgerRepository,
    required PdfStatementService pdfStatementService,
    ServiceReminderScheduler reminderScheduler =
        const NoopServiceReminderScheduler(),
  }) : this._(
         authRepository,
         ledgerRepository,
         pdfStatementService,
         reminderScheduler,
       );

  LedgerController._(
    AuthRepository authRepository,
    this._ledgerRepository,
    this._pdfStatementService,
    this._reminderScheduler,
  ) : _sessionController = SessionController(authRepository),
      _monthDataController = MonthDataController(_ledgerRepository),
      _entryOperations = EntryOperationsController(_ledgerRepository),
      _paymentOperations = PaymentOperationsController(_ledgerRepository) {
    unawaited(restoreCurrencyPreference());
    unawaited(restoreThemePreference());
    _authSubscription = _sessionController.watchProfile().listen(
      (nextProfile) => unawaited(_handleProfileChange(nextProfile)),
    );
  }

  static String defaultMonthKey() {
    return LedgerMonth.fromDate(DateTime.now()).key;
  }

  final LedgerRepository _ledgerRepository;
  final PdfStatementService _pdfStatementService;
  final ServiceReminderScheduler _reminderScheduler;
  final SessionController _sessionController;
  final MonthDataController _monthDataController;
  final EntryOperationsController _entryOperations;
  final PaymentOperationsController _paymentOperations;
  final GetServiceTillDateSummaryUseCase _getServiceTillDateSummary =
      const GetServiceTillDateSummaryUseCase();
  final CalculateEntryAmountUseCase _calculateEntryAmount =
      const CalculateEntryAmountUseCase();
  final ServiceStartDateResolver _serviceStartDateResolver =
      const ServiceStartDateResolver();
  final HomeSummaryBuilder _homeSummaryBuilder = const HomeSummaryBuilder();
  StreamSubscription<UserProfile?>? _authSubscription;
  Future<List<HomeServiceSummary>>? _homeSummariesFuture;
  int _homeSummariesRevision = 0;
  int _homeSummariesFutureRevision = -1;
  int _activeOperations = 0;
  bool _disposed = false;
  bool _notificationPermissionRequested = false;
  String _scheduledReminderSignature = '';

  LedgerRoute route = LedgerRoute.splash;
  bool isBackwardNavigation = false;
  LedgerOverview? overview;
  UserProfile? profile;
  HouseholdService? selectedService;
  PaymentTransaction? selectedPayment;
  int selectedDay = 29;
  EntrySource entrySource = EntrySource.calendar;
  PdfSource pdfSource = PdfSource.serviceDetail;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  late String monthKey = defaultMonthKey();
  DateTime quickLogDate = DateTime.now();
  String pendingVerificationEmail = '';
  String pendingPasswordResetEmail = '';
  AddServiceDraft? addServiceDraft;
  HouseholdService? editingService;
  AppCurrency selectedCurrency = AppCurrency.usd;
  final ValueNotifier<ThemeMode> themeModeListenable = ValueNotifier(
    ThemeMode.system,
  );

  bool get isAuthenticated => profile != null;
  bool get isEditingService => editingService != null;
  ThemeMode get selectedThemeMode => themeModeListenable.value;

  List<AppCurrency> get currencies => AppCurrency.values;

  Future<void> restoreThemePreference() async {
    final value = await _ledgerRepository.getLocalPreference(
      _themePreferenceKey,
    );
    themeModeListenable.value = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> selectThemeMode(ThemeMode mode) async {
    themeModeListenable.value = mode;
    notifyListeners();
    await _ledgerRepository.saveLocalPreference(
      key: _themePreferenceKey,
      value: mode.name,
    );
  }

  Future<void> restoreCurrencyPreference() async {
    final code = await _ledgerRepository.getLocalPreference(
      _currencyPreferenceKey,
    );
    selectedCurrency = AppCurrency.fromCode(code);
    CurrencyFormatter.setCurrency(selectedCurrency);
    notifyListeners();
  }

  Future<void> selectCurrency(AppCurrency currency) async {
    selectedCurrency = currency;
    CurrencyFormatter.setCurrency(currency);
    notifyListeners();
    await _ledgerRepository.saveLocalPreference(
      key: _currencyPreferenceKey,
      value: currency.code,
    );
  }

  Future<void> completeSplash() async {
    await _run(() async {
      try {
        final hasSeenOnboarding = await _ledgerRepository.getLocalPreference(
          _onboardingPreferenceKey,
        );
        if (hasSeenOnboarding != 'true') {
          _setRoute(LedgerRoute.onboarding);
          return;
        }
        profile = await _sessionController.restore(
          timeout: const Duration(seconds: 12),
        );
        if (profile == null) {
          _setRoute(LedgerRoute.login);
          return;
        }
        if (!profile!.emailVerified &&
            !_sessionController.isLocalDevelopmentProfile(profile!)) {
          _setRoute(LedgerRoute.emailVerificationPending);
          return;
        }
        await _openAuthenticatedDestination(profile!);
      } catch (_) {
        profile = null;
        _setRoute(LedgerRoute.login);
        rethrow;
      }
    });
  }

  Future<void> completeOnboarding() async {
    await _run(() async {
      await _ledgerRepository.saveLocalPreference(
        key: _onboardingPreferenceKey,
        value: 'true',
      );
      profile = null;
      _setRoute(LedgerRoute.login);
    });
  }

  Future<void> restoreSession() async {
    await _run(() async {
      profile = await _sessionController.restore();
      if (profile == null) {
        _setRoute(LedgerRoute.splash);
        return;
      }
      if (!profile!.emailVerified &&
          !_sessionController.isLocalDevelopmentProfile(profile!)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        return;
      }
      await _openAuthenticatedDestination(profile!);
    });
  }

  void goTo(LedgerRoute nextRoute) {
    _setRoute(nextRoute);
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void reviewAddService(AddServiceDraft draft) {
    addServiceDraft = draft;
    _setRoute(LedgerRoute.createServiceReview);
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void startCreateService() {
    editingService = null;
    addServiceDraft = null;
    _setRoute(LedgerRoute.createService);
    notifyListeners();
  }

  void startEditService(HouseholdService service) {
    editingService = service;
    addServiceDraft = AddServiceDraft.fromService(service);
    _setRoute(LedgerRoute.createService);
    notifyListeners();
  }

  Future<void> saveDraftService() async {
    final draft = addServiceDraft;
    if (draft == null) {
      _setRoute(LedgerRoute.createService);
      notifyListeners();
      return;
    }
    final amountCents = (draft.amount * 100).round();
    final serviceBeingEdited = editingService;
    if (serviceBeingEdited != null) {
      await updateService(
        service: serviceBeingEdited,
        startMonthKey: _monthKeyForDate(draft.startDate),
        name: draft.serviceName,
        description: draft.description,
        unit: draft.unit,
        defaultQuantity: draft.defaultQuantity,
        rateCents: amountCents,
        monthlyAmountCents:
            serviceBeingEdited.templateType == ServiceTemplateType.fixedMonthly
            ? amountCents
            : 0,
        routeAfterSave: LedgerRoute.calendar,
      );
      addServiceDraft = null;
      editingService = null;
      return;
    }
    await createService(
      startMonthKey: _monthKeyForDate(draft.startDate),
      name: draft.serviceName,
      description: draft.description,
      icon: draft.serviceIcon,
      templateType: draft.templateType,
      unit: draft.unit,
      defaultQuantity: draft.defaultQuantity,
      rateCents: amountCents,
      monthlyAmountCents: draft.templateType == ServiceTemplateType.fixedMonthly
          ? amountCents
          : 0,
      routeAfterSave: LedgerRoute.dashboard,
    );
    addServiceDraft = null;
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    await _run(() async {
      profile = await _sessionController.signIn(
        identifier: identifier,
        password: password,
      );
      if (!profile!.emailVerified &&
          !_sessionController.isLocalDevelopmentProfile(profile!)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        throw StateError('Please verify your email before opening the ledger.');
      }
      await _openAuthenticatedDestination(profile!);
    });
  }

  Future<void> bypassLoginForDevelopment() async {
    await _run(() async {
      profile = UserProfile(
        id: 'local-user',
        name: 'Local User',
        email: 'local@payqure.local',
        phone: '',
        emailVerified: true,
        privacyPolicyAccepted: true,
        privacyPolicyAcceptedAt: DateTime.now(),
        privacyPolicyVersion: LegalContent.policyVersion,
      );
      await _startLedger(profile!.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool privacyPolicyAccepted,
  }) async {
    await _run(() async {
      profile = await _sessionController.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        privacyPolicyAccepted: privacyPolicyAccepted,
      );
      pendingVerificationEmail = profile!.email;
      _setRoute(LedgerRoute.emailVerificationPending);
    });
  }

  Future<void> resendEmailVerification() async {
    final email = profile?.email ?? '';
    if (email.isEmpty) {
      errorMessage = 'Email is not available for this account.';
      notifyListeners();
      return;
    }
    await _run(() async {
      await _sessionController.resendEmailVerification(email);
      successMessage = 'Verification email sent again.';
    });
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _run(() async {
      profile = await _sessionController.verifyEmailOtp(
        email: email,
        token: token,
      );
      pendingVerificationEmail = '';
      await _openAuthenticatedDestination(profile!);
    });
  }

  Future<void> continueAfterEmailVerification() async {
    await _run(() async {
      final refreshed = await _sessionController.refresh();
      profile = refreshed ?? profile;
      final current = profile;
      if (current == null) {
        _setRoute(LedgerRoute.login);
        throw StateError('Sign in again after verifying your email.');
      }
      if (!current.emailVerified &&
          !_sessionController.isLocalDevelopmentProfile(current)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        throw StateError('We could not confirm your email yet.');
      }
      await _openAuthenticatedDestination(current);
    });
  }

  Future<void> acceptPrivacyPolicy() async {
    await _run(() async {
      profile = await _sessionController.acceptPrivacyPolicy();
      await _openAuthenticatedDestination(profile!);
    });
  }

  bool get requiresPrivacyPolicyAcceptance {
    final current = profile;
    return current != null &&
        _sessionController.requiresPrivacyAcceptance(current);
  }

  Future<void> requestPasswordReset(String email) async {
    await _run(() async {
      await _sessionController.requestPasswordReset(email);
      pendingPasswordResetEmail = email.trim();
      _setRoute(LedgerRoute.resetPasswordOtp);
    });
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _run(() async {
      await _sessionController.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      pendingPasswordResetEmail = '';
      successMessage = 'Password updated. Sign in with your new password.';
      _setRoute(LedgerRoute.login);
    });
  }

  void selectService(HouseholdService service) {
    selectedService = service;
    final startDate = _serviceStartDateResolver.resolve(service);
    final selectedMonth = _dateForMonthKey(monthKey);
    if (startDate != null &&
        startDate.year == selectedMonth.year &&
        startDate.month == selectedMonth.month &&
        selectedDay < startDate.day) {
      selectedDay = startDate.day;
    }
    _setRoute(LedgerRoute.calendar);
    notifyListeners();
  }

  void selectDayForEdit(int day, {EntrySource source = EntrySource.calendar}) {
    selectedDay = day;
    entrySource = source;
    _setRoute(LedgerRoute.entry);
    notifyListeners();
  }

  void selectDayInline(int day) {
    selectedDay = day;
    notifyListeners();
  }

  void openPdfPreview({PdfSource source = PdfSource.serviceDetail}) {
    pdfSource = source;
    _setRoute(LedgerRoute.pdfPreview);
    notifyListeners();
  }

  void openSettlementDetail(HouseholdService service) {
    selectedService = service;
    _setRoute(LedgerRoute.settlementDetail);
    notifyListeners();
  }

  void openPaymentHistory(HouseholdService service) {
    selectedService = service;
    selectedPayment = null;
    _setRoute(LedgerRoute.paymentHistory);
    notifyListeners();
  }

  void openPaymentDetail(PaymentTransaction payment) {
    selectedPayment = payment;
    _setRoute(LedgerRoute.paymentDetail);
    notifyListeners();
  }

  Future<void> openQuickLog({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    quickLogDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    selectedDay = quickLogDate.day;
    final targetMonthKey = _monthKeyForDate(quickLogDate);
    final userId = profile?.id ?? overview?.profile.id;
    if (userId != null && targetMonthKey != monthKey) {
      await _run(() async {
        final loaded = await _loadMonth(
          userId: userId,
          nextMonthKey: targetMonthKey,
        );
        if (!loaded) {
          return;
        }
        _setRoute(LedgerRoute.quickLog);
      });
      return;
    }
    _setRoute(LedgerRoute.quickLog);
    notifyListeners();
  }

  Future<void> setQuickLogDate(DateTime date) async {
    quickLogDate = DateTime(date.year, date.month, date.day);
    selectedDay = quickLogDate.day;
    final targetMonthKey = _monthKeyForDate(quickLogDate);
    final userId = profile?.id ?? overview?.profile.id;
    if (userId != null && targetMonthKey != monthKey) {
      await _run(() async {
        final loaded = await _loadMonth(
          userId: userId,
          nextMonthKey: targetMonthKey,
        );
        if (!loaded) {
          return;
        }
        _setRoute(LedgerRoute.quickLog);
      });
      return;
    }
    notifyListeners();
  }

  Future<void> goToPreviousMonth() => _changeMonth(-1);

  Future<void> goToNextMonth() => _changeMonth(1);

  Future<void> selectMonth(String nextMonthKey) async {
    final userId = profile?.id ?? overview?.profile.id;
    if (userId == null || nextMonthKey == monthKey) {
      return;
    }
    await _run(() async {
      final loaded = await _loadMonth(
        userId: userId,
        nextMonthKey: nextMonthKey,
      );
      if (!loaded) {
        return;
      }
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> _changeMonth(int delta) {
    return selectMonth(_shiftMonth(monthKey, delta));
  }

  Future<void> refreshSelectedMonth() async {
    final userId = profile?.id ?? overview?.profile.id;
    if (userId == null) {
      return;
    }
    await _run(() async {
      await _monthDataController.hydrate(
        userId: userId,
        monthKey: monthKey,
        forceRefresh: true,
      );
      await _refreshLedgerState(resetSelection: false);
      successMessage = 'Month refreshed.';
    });
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    await _run(() async {
      profile = await _sessionController.updateProfile(
        name: name,
        phone: phone,
      );
      successMessage = 'Profile updated.';
      _setRoute(LedgerRoute.profile);
    });
  }

  Future<void> createService({
    String? startMonthKey,
    required String name,
    required String description,
    required String icon,
    required ServiceTemplateType templateType,
    required String unit,
    required double defaultQuantity,
    required int rateCents,
    required int monthlyAmountCents,
    LedgerRoute routeAfterSave = LedgerRoute.calendar,
  }) async {
    final userId = profile?.id ?? 'local-user';
    await _run(() async {
      selectedService = await _ledgerRepository.createService(
        userId: userId,
        monthKey: startMonthKey ?? monthKey,
        name: name,
        description: description,
        icon: icon,
        templateType: templateType.name,
        unit: unit,
        defaultQuantity: defaultQuantity,
        rateCents: rateCents,
        monthlyAmountCents: monthlyAmountCents,
      );
      _setRoute(routeAfterSave);
    });
  }

  Future<void> updateService({
    required HouseholdService service,
    String? startMonthKey,
    required String name,
    required String description,
    required String unit,
    required double defaultQuantity,
    required int rateCents,
    required int monthlyAmountCents,
    LedgerRoute routeAfterSave = LedgerRoute.calendar,
  }) async {
    await _run(() async {
      selectedService = await _ledgerRepository.updateService(
        id: service.id,
        monthKey: startMonthKey ?? service.monthKey,
        name: name,
        description: description,
        unit: unit,
        defaultQuantity: defaultQuantity,
        rateCents: rateCents,
        monthlyAmountCents: monthlyAmountCents,
      );
      final userId = profile?.id ?? overview?.profile.id;
      if (userId != null) {
        await _startLedger(userId, resetSelection: false);
      }
      _setRoute(routeAfterSave);
    });
  }

  Future<void> deleteService(HouseholdService service) async {
    await _run(() async {
      await _ledgerRepository.deleteService(
        serviceId: service.id,
        monthKey: monthKey,
      );
      selectedService = null;
      addServiceDraft = null;
      editingService = null;
      final userId = profile?.id ?? overview?.profile.id;
      if (userId != null) {
        await _startLedger(userId, resetSelection: true);
      }
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> saveSelectedEntry({
    required ServiceEntryStatus status,
    required double quantity,
    required String unit,
    required int rateCents,
    required String note,
  }) async {
    final service = selectedService;
    if (service == null) {
      return;
    }
    await _run(() async {
      await _entryOperations.save(
        service: service,
        monthKey: monthKey,
        day: selectedDay,
        status: status,
        quantity: quantity,
        unit: unit,
        rateCents: rateCents,
        note: note,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      await _refreshLedgerState(resetSelection: false);
      _setRoute(_entryReturnRoute());
    });
  }

  Future<void> saveDefaultEntryForService({
    required HouseholdService service,
    required int day,
    ServiceEntryStatus? status,
  }) async {
    await _run(() async {
      await _entryOperations.saveDefault(
        service: service,
        monthKey: monthKey,
        day: day,
        status: status,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      await _refreshLedgerState(resetSelection: false);
    });
  }

  Future<void> saveQuickEntryForService({
    required HouseholdService service,
    required int day,
    required ServiceEntryStatus status,
  }) async {
    try {
      await _entryOperations.saveDefault(
        service: service,
        monthKey: monthKey,
        day: day,
        status: status,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      await _refreshLedgerState(resetSelection: false);
    } catch (error) {
      errorMessage = ErrorMessageMapper.userFacing(error);
      notifyListeners();
    }
  }

  DateTime _dateForMonthKey(String key) {
    return LedgerMonth.parse(key).firstDay;
  }

  Future<void> clearQuickEntryForService({
    required HouseholdService service,
    required int day,
  }) async {
    try {
      await _entryOperations.clear(
        service: service,
        monthKey: monthKey,
        day: day,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      await _refreshLedgerState(resetSelection: false);
    } catch (error) {
      errorMessage = ErrorMessageMapper.userFacing(error);
      notifyListeners();
    }
  }

  Future<void> saveDefaultsForAllServices({
    required List<HouseholdService> services,
    required int day,
  }) async {
    await _run(() async {
      for (final service in services) {
        await _entryOperations.saveDefault(
          service: service,
          monthKey: monthKey,
          day: day,
          status: ServiceEntryStatus.delivered,
          onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
        );
      }
      await _refreshLedgerState(resetSelection: false);
    });
  }

  Future<void> clearEntryForService({
    required HouseholdService service,
    required int day,
  }) async {
    await _run(() async {
      await _entryOperations.clear(
        service: service,
        monthKey: monthKey,
        day: day,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      await _refreshLedgerState(resetSelection: false);
    });
  }

  Future<void> saveAdvance({
    required int amountCents,
    DateTime? paidOn,
    String note = '',
  }) async {
    final service = selectedService;
    if (service == null) {
      return;
    }
    await _run(() async {
      await _paymentOperations.saveAdvance(
        service: service,
        monthKey: monthKey,
        amountCents: amountCents,
        paidOn: paidOn ?? DateTime.now(),
        note: note,
      );
      _invalidateHomeSummaries();
    });
  }

  Future<void> savePayment({
    required int amountCents,
    required DateTime paymentDate,
    required PaymentMode mode,
    String note = '',
  }) async {
    final service = selectedService;
    final userId = profile?.id ?? overview?.profile.id ?? 'local-user';
    if (service == null) {
      return;
    }
    await _run(() async {
      await _paymentOperations.savePayment(
        userId: userId,
        service: service,
        monthKey: monthKey,
        amountCents: amountCents,
        paymentDate: paymentDate,
        mode: mode,
        note: note,
      );
      _invalidateHomeSummaries();
      successMessage = 'Payment recorded.';
      _setRoute(LedgerRoute.calendar);
    });
  }

  Future<void> updatePayment({
    required PaymentTransaction payment,
    required int amountCents,
    required DateTime paymentDate,
    required PaymentMode mode,
    String note = '',
  }) async {
    await _run(() async {
      await _paymentOperations.updatePayment(
        payment: payment,
        amountCents: amountCents,
        paymentDate: paymentDate,
        mode: mode,
        note: note,
      );
      _invalidateHomeSummaries();
      selectedPayment = null;
      successMessage = 'Payment updated.';
      _setRoute(LedgerRoute.paymentHistory);
    });
  }

  Future<void> deletePayment(PaymentTransaction payment) async {
    await _run(() async {
      await _paymentOperations.deletePayment(payment);
      _invalidateHomeSummaries();
      selectedPayment = null;
      successMessage = 'Payment deleted.';
      _setRoute(LedgerRoute.paymentHistory);
    });
  }

  Future<List<PaymentTransaction>> loadSelectedPaymentHistory() async {
    final service = selectedService;
    if (service == null) {
      return const [];
    }
    return _paymentOperations.paymentHistory(service.id);
  }

  Future<PaymentSettlementPreview> loadPaymentSettlementPreview({
    required HouseholdService service,
    required int paymentCents,
    String? forMonthKey,
  }) {
    return _paymentOperations.settlementPreview(
      service: service,
      monthKey: forMonthKey ?? monthKey,
      paymentCents: paymentCents,
    );
  }

  Future<List<ServiceHistoryItem>> loadGlobalPaymentHistory() async {
    final services = overview?.services ?? const <HouseholdService>[];
    return _paymentOperations.globalPaymentHistory(services);
  }

  Future<List<ServiceHistoryItem>> loadGlobalAdvanceHistory() async {
    final services = overview?.services ?? const <HouseholdService>[];
    return _paymentOperations.globalAdvanceHistory(services);
  }

  Future<MonthlyBill?> loadSelectedBill() async {
    final service = selectedService;
    if (service == null) {
      return null;
    }
    return _ledgerRepository.getMonthlyBill(
      serviceId: service.id,
      monthKey: monthKey,
    );
  }

  Future<MonthlyBill> loadBillForService(
    HouseholdService service, {
    String? forMonthKey,
  }) {
    return _ledgerRepository.getMonthlyBill(
      serviceId: service.id,
      monthKey: forMonthKey ?? monthKey,
    );
  }

  Future<ServiceTillDateSummary> loadTillDateSummaryForService(
    HouseholdService service, {
    String? forMonthKey,
  }) async {
    final activeMonthKey = forMonthKey ?? monthKey;
    final advances = await _ledgerRepository.getAdvances(
      serviceId: service.id,
      monthKey: activeMonthKey,
    );
    final payments = await _ledgerRepository.getPayments(
      serviceId: service.id,
      monthKey: activeMonthKey,
    );
    MonthlySettlement? previousSettlement;
    try {
      previousSettlement = await _ledgerRepository.getSettlement(
        serviceId: service.id,
        monthKey: _shiftMonth(activeMonthKey, -1),
      );
    } catch (_) {
      previousSettlement = null;
    }
    return _getServiceTillDateSummary(
      service: service,
      monthKey: activeMonthKey,
      advances: advances,
      payments: payments,
      previousSettlement: previousSettlement,
    );
  }

  EntryAmountBreakdown calculateEntryAmount({
    required HouseholdService service,
    required ServiceEntryStatus status,
    required double quantity,
    required int rateCents,
  }) {
    return _calculateEntryAmount(
      service: service,
      status: status,
      quantity: quantity,
      rateCents: rateCents,
    );
  }

  Future<List<HomeServiceSummary>> loadHomeServiceSummaries() {
    if (_homeSummariesFuture != null &&
        _homeSummariesFutureRevision == _homeSummariesRevision) {
      return _homeSummariesFuture!;
    }
    final activeMonthKey = monthKey;
    final services = List<HouseholdService>.unmodifiable(
      overview?.services ?? const <HouseholdService>[],
    );
    final future = Future.wait(
      services.map(
        (service) => _buildHomeServiceSummary(service, activeMonthKey),
      ),
    );
    _homeSummariesFuture = future;
    _homeSummariesFutureRevision = _homeSummariesRevision;
    return future;
  }

  Future<HomeServiceSummary> _buildHomeServiceSummary(
    HouseholdService service,
    String activeMonthKey,
  ) async {
    final tillDate = await loadTillDateSummaryForService(
      service,
      forMonthKey: activeMonthKey,
    );
    return _homeSummaryBuilder.buildServiceSummary(
      service: service,
      tillDate: tillDate,
    );
  }

  HomeMonthlySummary buildHomeMonthlySummary(
    List<HomeServiceSummary> summaries,
  ) {
    return _homeSummaryBuilder.buildMonthlySummary(summaries);
  }

  Future<Uint8List?> buildSelectedPdf() async {
    final bill = await loadSelectedBill();
    if (bill == null) {
      return null;
    }
    return _pdfStatementService.buildStatement(bill);
  }

  Future<void> signOut() async {
    await _run(() async {
      final currentProfile = profile;
      if (currentProfile != null &&
          !_sessionController.isLocalDevelopmentProfile(currentProfile)) {
        await _ledgerRepository.syncUserDataAndClearLocal(
          userId: currentProfile.id,
        );
      }
      await _monthDataController.cancel();
      await _reminderScheduler.cancelServiceReminders();
      await _sessionController.signOut();
      profile = null;
      overview = null;
      selectedService = null;
      _setRoute(LedgerRoute.login);
    });
  }

  Future<void> ensureHomeNotificationsConfigured() async {
    final services = overview?.services ?? const <HouseholdService>[];
    final signature = services
        .map((service) => '${service.id}:${service.description}')
        .join('|');
    if (_notificationPermissionRequested &&
        signature == _scheduledReminderSignature) {
      return;
    }
    _notificationPermissionRequested = true;
    final granted = await _reminderScheduler.requestPermission();
    if (!granted) {
      return;
    }
    await _reminderScheduler.scheduleServices(services);
    _scheduledReminderSignature = signature;
  }

  Future<void> _handleProfileChange(UserProfile? nextProfile) async {
    profile = nextProfile;
    if (nextProfile == null) {
      await _monthDataController.cancel();
      overview = null;
      selectedService = null;
      if (route != LedgerRoute.splash &&
          route != LedgerRoute.login &&
          route != LedgerRoute.register) {
        _setRoute(LedgerRoute.login);
      }
      notifyListeners();
      return;
    }

    if (route == LedgerRoute.emailVerificationPending &&
        nextProfile.emailVerified) {
      await _openAuthenticatedDestination(nextProfile);
      notifyListeners();
    }
  }

  Future<void> _openAuthenticatedDestination(UserProfile current) async {
    if (_sessionController.requiresPrivacyAcceptance(current)) {
      _setRoute(LedgerRoute.privacyPolicyAcceptance);
      return;
    }
    monthKey = defaultMonthKey();
    await _monthDataController.hydrate(
      userId: current.id,
      monthKey: monthKey,
      forceRefresh: true,
      useCacheOnFailure: true,
    );
    await _startLedger(current.id, resetSelection: true);
    _setRoute(LedgerRoute.dashboard);
  }

  Future<void> _startLedger(
    String userId, {
    bool resetSelection = false,
  }) async {
    final activeMonthKey = monthKey;
    await _monthDataController.start(
      userId: userId,
      monthKey: activeMonthKey,
      onOverview: (nextOverview) {
        if (activeMonthKey != monthKey) {
          return;
        }
        overview = nextOverview;
        selectedService = _selectedServiceForOverview(
          nextOverview,
          resetSelection: resetSelection,
        );
        resetSelection = false;
        _invalidateHomeSummaries();
        notifyListeners();
      },
    );
  }

  Future<bool> _loadMonth({
    required String userId,
    required String nextMonthKey,
  }) async {
    var resetSelection = true;
    return _monthDataController.switchMonth(
      userId: userId,
      monthKey: nextMonthKey,
      onActivated: () {
        monthKey = nextMonthKey;
        selectedDay = 1;
        selectedService = null;
        overview = null;
      },
      onOverview: (nextOverview) {
        if (nextMonthKey != monthKey) {
          return;
        }
        overview = nextOverview;
        selectedService = _selectedServiceForOverview(
          nextOverview,
          resetSelection: resetSelection,
        );
        resetSelection = false;
        _invalidateHomeSummaries();
        notifyListeners();
      },
    );
  }

  HouseholdService? _selectedServiceForOverview(
    LedgerOverview nextOverview, {
    required bool resetSelection,
  }) {
    if (nextOverview.services.isEmpty) {
      return null;
    }
    if (!resetSelection && selectedService != null) {
      final existing = nextOverview.services.where(
        (service) => service.id == selectedService!.id,
      );
      if (existing.isNotEmpty) {
        return existing.first;
      }
    }
    return nextOverview.services.first;
  }

  Future<void> _refreshLedgerState({required bool resetSelection}) async {
    final userId = profile?.id ?? overview?.profile.id;
    if (userId == null) {
      notifyListeners();
      return;
    }
    final nextOverview = await _monthDataController.refresh(
      userId: userId,
      monthKey: monthKey,
    );
    if (nextOverview == null) {
      return;
    }
    overview = nextOverview;
    selectedService = _selectedServiceForOverview(
      overview!,
      resetSelection: resetSelection,
    );
    _invalidateHomeSummaries();
    notifyListeners();
  }

  String _shiftMonth(String key, int delta) {
    return LedgerMonth.parse(key).shift(delta).key;
  }

  String _monthKeyForDate(DateTime date) {
    return LedgerMonth.fromDate(date).key;
  }

  LedgerRoute _entryReturnRoute() {
    return switch (entrySource) {
      EntrySource.quickLog => LedgerRoute.quickLog,
      EntrySource.calendar => LedgerRoute.calendar,
    };
  }

  void _applyOptimisticEntry(String serviceId, ServiceEntry entry) {
    HouseholdService patchService(HouseholdService service) {
      final entries = [...service.entries];
      final index = entries.indexWhere(
        (existing) =>
            existing.day == entry.day && existing.monthKey == entry.monthKey,
      );
      if (index == -1) {
        entries.add(entry);
      } else {
        entries[index] = entry;
      }
      entries.sort((a, b) => a.day.compareTo(b.day));
      return service.copyWith(entries: entries, updatedAt: DateTime.now());
    }

    if (selectedService?.id == serviceId) {
      selectedService = patchService(selectedService!);
    }

    final currentOverview = overview;
    if (currentOverview != null) {
      final services = currentOverview.services
          .map(
            (service) =>
                service.id == serviceId ? patchService(service) : service,
          )
          .toList();
      overview = LedgerOverview(
        profile: currentOverview.profile,
        monthKey: currentOverview.monthKey,
        monthLabel: currentOverview.monthLabel,
        services: services,
        totalPayableCents: currentOverview.totalPayableCents,
        advancePaidCents: currentOverview.advancePaidCents,
      );
    }
    notifyListeners();
  }

  void _invalidateHomeSummaries() {
    _homeSummariesRevision++;
    _homeSummariesFuture = null;
  }

  void _setRoute(LedgerRoute nextRoute) {
    isBackwardNavigation = _routeDepth(nextRoute) < _routeDepth(route);
    route = nextRoute;
  }

  int _routeDepth(LedgerRoute route) {
    return switch (route) {
      LedgerRoute.splash => 0,
      LedgerRoute.onboarding => 1,
      LedgerRoute.login ||
      LedgerRoute.register ||
      LedgerRoute.emailVerificationPending ||
      LedgerRoute.forgotPassword ||
      LedgerRoute.resetPasswordOtp => 1,
      LedgerRoute.privacyPolicyAcceptance => 2,
      LedgerRoute.dashboard || LedgerRoute.more => 2,
      LedgerRoute.quickLog ||
      LedgerRoute.createService ||
      LedgerRoute.paymentHistory ||
      LedgerRoute.globalPaymentHistory ||
      LedgerRoute.advanceHistory ||
      LedgerRoute.contacts ||
      LedgerRoute.profile ||
      LedgerRoute.currency ||
      LedgerRoute.theme => 3,
      LedgerRoute.privacyPolicy ||
      LedgerRoute.termsDisclaimer ||
      LedgerRoute.deleteMyData => 3,
      LedgerRoute.createServiceReview ||
      LedgerRoute.calendar ||
      LedgerRoute.settlementDetail ||
      LedgerRoute.paymentDetail => 4,
      LedgerRoute.entry => 5,
      LedgerRoute.pdfPreview => 6,
    };
  }

  Future<void> _run(Future<void> Function() action) async {
    _activeOperations++;
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = ErrorMessageMapper.userFacing(error);
    } finally {
      _activeOperations--;
      isLoading = _activeOperations > 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    _monthDataController.dispose();
    themeModeListenable.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
