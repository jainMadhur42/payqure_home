import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/error_message_mapper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/services/pdf_statement_service.dart';
import '../../domain/entities/advance_payment.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_overview.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/service_template_catalog.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/entry_amount_calculator.dart';
import '../../domain/services/entry_value_resolver.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../../domain/usecases/ledger_calculation_usecases.dart';

enum EntrySource { quickLog, calendar }

enum PdfSource { serviceDetail, bills }

class LedgerController extends ChangeNotifier {
  static const _currencyPreferenceKey = 'currency_code';
  static const _themePreferenceKey = 'theme_mode';

  LedgerController({
    required AuthRepository authRepository,
    required LedgerRepository ledgerRepository,
    required PdfStatementService pdfStatementService,
  }) : this._(authRepository, ledgerRepository, pdfStatementService);

  LedgerController._(
    this._authRepository,
    this._ledgerRepository,
    this._pdfStatementService,
  ) {
    unawaited(restoreCurrencyPreference());
    unawaited(restoreThemePreference());
    _authSubscription = _authRepository.watchProfile().listen(
      (nextProfile) => unawaited(_handleProfileChange(nextProfile)),
    );
  }

  static String defaultMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  final AuthRepository _authRepository;
  final LedgerRepository _ledgerRepository;
  final PdfStatementService _pdfStatementService;
  final GetServiceTillDateSummaryUseCase _getServiceTillDateSummary =
      const GetServiceTillDateSummaryUseCase();
  final CalculateEntryAmountUseCase _calculateEntryAmount =
      const CalculateEntryAmountUseCase();
  final ServiceStartDateResolver _serviceStartDateResolver =
      const ServiceStartDateResolver();
  final EntryValueResolver _entryValueResolver = const EntryValueResolver();
  StreamSubscription<UserProfile?>? _authSubscription;
  StreamSubscription<LedgerOverview>? _overviewSubscription;

  LedgerRoute route = LedgerRoute.splash;
  bool isBackwardNavigation = false;
  LedgerOverview? overview;
  UserProfile? profile;
  HouseholdService? selectedService;
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
  ThemeMode selectedThemeMode = ThemeMode.system;

  bool get isAuthenticated => profile != null;
  bool get isEditingService => editingService != null;

  List<AppCurrency> get currencies => AppCurrency.values;

  Future<void> restoreThemePreference() async {
    final value = await _ledgerRepository.getLocalPreference(
      _themePreferenceKey,
    );
    selectedThemeMode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> selectThemeMode(ThemeMode mode) async {
    selectedThemeMode = mode;
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
      profile = await _authRepository.restoreSession();
      if (profile == null) {
        _setRoute(LedgerRoute.login);
        return;
      }
      if (!profile!.emailVerified && !_isLocalDevProfile(profile!)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        return;
      }
      await _startLedger(profile!.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> restoreSession() async {
    await _run(() async {
      profile = await _authRepository.restoreSession();
      if (profile == null) {
        _setRoute(LedgerRoute.splash);
        return;
      }
      if (!profile!.emailVerified && !_isLocalDevProfile(profile!)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        return;
      }
      await _startLedger(profile!.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
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
      await _authRepository.signIn(identifier: identifier, password: password);
      profile = _authRepository.currentProfile;
      if (profile == null) {
        throw StateError('Sign in did not return a user profile.');
      }
      if (!profile!.emailVerified && !_isLocalDevProfile(profile!)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        throw StateError('Please verify your email before opening the ledger.');
      }
      await _startLedger(profile!.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> bypassLoginForDevelopment() async {
    await _run(() async {
      profile = const UserProfile(
        id: 'local-user',
        name: 'Local User',
        email: 'local@payqure.local',
        phone: '',
        emailVerified: true,
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
  }) async {
    await _run(() async {
      await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      profile = _authRepository.currentProfile;
      if (profile == null) {
        throw StateError('Profile not set after registration.');
      }
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
      await _authRepository.resendEmailVerification(email);
      successMessage = 'Verification email sent again.';
    });
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _run(() async {
      profile = await _authRepository.verifyEmailOtp(
        email: email,
        token: token,
      );
      pendingVerificationEmail = '';
      await _startLedger(profile!.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> continueAfterEmailVerification() async {
    await _run(() async {
      final refreshed = await _authRepository.refreshProfile();
      profile = refreshed ?? profile;
      final current = profile;
      if (current == null) {
        _setRoute(LedgerRoute.login);
        throw StateError('Sign in again after verifying your email.');
      }
      if (!current.emailVerified && !_isLocalDevProfile(current)) {
        _setRoute(LedgerRoute.emailVerificationPending);
        throw StateError('We could not confirm your email yet.');
      }
      await _startLedger(current.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> requestPasswordReset(String email) async {
    await _run(() async {
      await _authRepository.requestPasswordReset(email);
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
      await _authRepository.resetPasswordWithOtp(
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
    _setRoute(LedgerRoute.paymentHistory);
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
        monthKey = targetMonthKey;
        selectedService = null;
        overview = null;
        await _startLedger(userId, resetSelection: true);
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
        monthKey = targetMonthKey;
        selectedService = null;
        overview = null;
        await _startLedger(userId, resetSelection: true);
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
      monthKey = nextMonthKey;
      selectedDay = 1;
      selectedService = null;
      overview = null;
      await _startLedger(userId, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> _changeMonth(int delta) async {
    final userId = profile?.id ?? overview?.profile.id;
    if (userId == null) {
      return;
    }
    await _run(() async {
      monthKey = _shiftMonth(monthKey, delta);
      selectedDay = 1;
      selectedService = null;
      overview = null;
      await _startLedger(userId, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    await _run(() async {
      profile = await _authRepository.updateProfile(name: name, phone: phone);
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
      await _saveEntryForService(
        service: service,
        day: selectedDay,
        status: status,
        quantity: quantity,
        unit: unit,
        rateCents: rateCents,
        note: note,
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
      await _saveEntryForService(
        service: service,
        day: day,
        status: status ?? ServiceEntryStatus.delivered,
        quantity: _defaultQuantityFor(service, status),
        unit: service.unit,
        rateCents: _defaultRateFor(service),
        note: '',
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
      _ensureEntryDateIsValid(service: service, day: day);
      await _saveEntryForService(
        service: service,
        day: day,
        status: status,
        quantity: _defaultQuantityFor(service, status),
        unit: service.unit,
        rateCents: _defaultRateFor(service),
        note: '',
      );
      await _refreshLedgerState(resetSelection: false);
    } catch (error) {
      errorMessage = ErrorMessageMapper.userFacing(error);
      notifyListeners();
    }
  }

  void _ensureEntryDateIsValid({
    required HouseholdService service,
    required int day,
  }) {
    final startDate = _serviceStartDateResolver.resolve(service);
    if (startDate == null) {
      return;
    }
    final month = _dateForMonthKey(monthKey);
    final entryDate = DateTime(month.year, month.month, day);
    if (entryDate.isBefore(startDate)) {
      throw StateError(
        'Entries cannot be added before the service start date.',
      );
    }
  }

  DateTime _dateForMonthKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.tryParse(parts.first) ?? DateTime.now().year,
      parts.length > 1
          ? int.tryParse(parts[1]) ?? DateTime.now().month
          : DateTime.now().month,
    );
  }

  Future<void> clearQuickEntryForService({
    required HouseholdService service,
    required int day,
  }) async {
    try {
      await _saveEntryForService(
        service: service,
        day: day,
        status: ServiceEntryStatus.noEntry,
        quantity: 0,
        unit: service.unit,
        rateCents: 0,
        note: '',
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
        await _saveEntryForService(
          service: service,
          day: day,
          status: ServiceEntryStatus.delivered,
          quantity: _defaultQuantityFor(service, ServiceEntryStatus.delivered),
          unit: service.unit,
          rateCents: _defaultRateFor(service),
          note: '',
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
      await _saveEntryForService(
        service: service,
        day: day,
        status: ServiceEntryStatus.noEntry,
        quantity: 0,
        unit: service.unit,
        rateCents: 0,
        note: '',
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
      await _ledgerRepository.saveAdvance(
        AdvancePayment(
          id: IdGenerator.create('advance'),
          serviceId: service.id,
          monthKey: monthKey,
          amountCents: amountCents,
          paidOn: paidOn ?? DateTime.now(),
          note: note,
        ),
      );
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
      await _ledgerRepository.savePayment(
        PaymentTransaction(
          id: IdGenerator.create('payment'),
          userId: userId,
          serviceId: service.id,
          monthKey: monthKey,
          amountCents: amountCents,
          paymentDate: paymentDate,
          mode: mode,
          note: note,
          updatedAt: DateTime.now(),
          pendingSync: true,
        ),
      );
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
      await _ledgerRepository.savePayment(
        payment.copyWith(
          amountCents: amountCents,
          paymentDate: paymentDate,
          mode: mode,
          note: note,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
      successMessage = 'Payment updated.';
      _setRoute(LedgerRoute.paymentHistory);
    });
  }

  Future<void> deletePayment(PaymentTransaction payment) async {
    await _run(() async {
      await _ledgerRepository.deletePayment(payment);
      successMessage = 'Payment deleted.';
      _setRoute(LedgerRoute.paymentHistory);
    });
  }

  Future<List<PaymentTransaction>> loadSelectedPaymentHistory() async {
    final service = selectedService;
    if (service == null) {
      return const [];
    }
    return _ledgerRepository.getPaymentHistory(serviceId: service.id);
  }

  Future<List<ServiceHistoryItem>> loadGlobalPaymentHistory() async {
    final services = overview?.services ?? const <HouseholdService>[];
    final items = <ServiceHistoryItem>[];
    for (final service in services) {
      final payments = await _ledgerRepository.getPaymentHistory(
        serviceId: service.id,
      );
      items.addAll(
        payments.map(
          (payment) => ServiceHistoryItem(
            id: payment.id,
            service: service,
            type: ServiceHistoryType.payment,
            amountCents: payment.amountCents,
            date: payment.paymentDate,
            modeLabel: payment.mode.label,
            note: payment.note,
            pendingSync: payment.pendingSync,
          ),
        ),
      );
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<List<ServiceHistoryItem>> loadGlobalAdvanceHistory() async {
    final services = overview?.services ?? const <HouseholdService>[];
    final items = <ServiceHistoryItem>[];
    for (final service in services) {
      final advances = await _ledgerRepository.getAdvanceHistory(
        serviceId: service.id,
      );
      items.addAll(
        advances.map(
          (advance) => ServiceHistoryItem(
            id: advance.id,
            service: service,
            type: ServiceHistoryType.advance,
            amountCents: advance.amountCents,
            date: advance.paidOn,
            modeLabel: 'Advance',
            note: advance.note,
            pendingSync: advance.pendingSync,
          ),
        ),
      );
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
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

  Future<MonthlyBill> loadBillForService(HouseholdService service) {
    return _ledgerRepository.getMonthlyBill(
      serviceId: service.id,
      monthKey: monthKey,
    );
  }

  Future<ServiceTillDateSummary> loadTillDateSummaryForService(
    HouseholdService service,
  ) async {
    final advances = await _ledgerRepository.getAdvances(
      serviceId: service.id,
      monthKey: monthKey,
    );
    final payments = await _ledgerRepository.getPayments(
      serviceId: service.id,
      monthKey: monthKey,
    );
    MonthlySettlement? previousSettlement;
    try {
      previousSettlement = await _ledgerRepository.getSettlement(
        serviceId: service.id,
        monthKey: _shiftMonth(monthKey, -1),
      );
    } catch (_) {
      previousSettlement = null;
    }
    return _getServiceTillDateSummary(
      service: service,
      monthKey: monthKey,
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

  Future<List<HomeServiceSummary>> loadHomeServiceSummaries() async {
    final services = overview?.services ?? const <HouseholdService>[];
    final summaries = <HomeServiceSummary>[];
    for (final service in services) {
      final bill = await loadBillForService(service);
      final tillDate = await loadTillDateSummaryForService(service);
      final settlement = tillDate.settlement;
      final payableCents = settlement.usageAmountCents;
      final paidCents = settlement.paidThisMonthCents;
      final remainingCents = settlement.carryForwardCents;
      final advanceCents = settlement.advanceBalanceCents;
      final statusLabel = settlement.status.label;
      final primaryLabel = advanceCents > 0
          ? 'Advance'
          : remainingCents > 0
          ? 'Due till today'
          : settlement.status == SettlementStatus.paid
          ? 'Paid'
          : 'Pending';
      final primaryAmountCents = advanceCents > 0
          ? advanceCents
          : remainingCents > 0
          ? remainingCents
          : settlement.status == SettlementStatus.paid
          ? paidCents
          : 0;
      summaries.add(
        HomeServiceSummary(
          service: service,
          bill: bill,
          metricLabel: _serviceMetricFor(service),
          payableCents: payableCents,
          paidCents: paidCents,
          remainingCents: remainingCents,
          advanceCents: advanceCents,
          usageCents: payableCents,
          previousPendingCents: settlement.previousBalanceRemainingCents,
          advanceUsedCents: settlement.advanceUsedCents,
          deliveredDays: tillDate.usage.deliveredDays,
          missedDays: tillDate.usage.missedDays,
          totalQuantity: tillDate.usage.totalQuantity,
          statusLabel: statusLabel,
          primaryLabel: primaryLabel,
          primaryAmountCents: primaryAmountCents,
        ),
      );
    }
    return summaries;
  }

  HomeMonthlySummary buildHomeMonthlySummary(
    List<HomeServiceSummary> summaries,
  ) {
    return HomeMonthlySummary(
      totalDueCents: summaries.fold(
        0,
        (sum, summary) => sum + summary.remainingCents,
      ),
      usageCents: summaries.fold(0, (sum, summary) => sum + summary.usageCents),
      previousPendingCents: summaries.fold(
        0,
        (sum, summary) => sum + summary.previousPendingCents,
      ),
      paidCents: summaries.fold(0, (sum, summary) => sum + summary.paidCents),
      advanceCents: summaries.fold(
        0,
        (sum, summary) => sum + summary.advanceUsedCents,
      ),
      serviceCount: summaries.length,
    );
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
      if (currentProfile != null && !_isLocalDevProfile(currentProfile)) {
        await _ledgerRepository.syncUserDataAndClearLocal(
          userId: currentProfile.id,
        );
      }
      await _overviewSubscription?.cancel();
      await _authRepository.signOut();
      profile = null;
      overview = null;
      selectedService = null;
      _setRoute(LedgerRoute.login);
    });
  }

  Future<void> _handleProfileChange(UserProfile? nextProfile) async {
    profile = nextProfile;
    if (nextProfile == null) {
      await _overviewSubscription?.cancel();
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
      await _startLedger(nextProfile.id, resetSelection: true);
      _setRoute(LedgerRoute.dashboard);
      notifyListeners();
    }
  }

  Future<void> _startLedger(
    String userId, {
    bool resetSelection = false,
  }) async {
    await _overviewSubscription?.cancel();
    final activeMonthKey = monthKey;
    _overviewSubscription = _ledgerRepository
        .watchOverview(userId: userId, monthKey: activeMonthKey)
        .listen((nextOverview) {
          if (nextOverview.monthKey != monthKey) {
            return;
          }
          overview = nextOverview;
          selectedService = _selectedServiceForOverview(
            nextOverview,
            resetSelection: resetSelection,
          );
          resetSelection = false;
          notifyListeners();
        });
    overview = await _ledgerRepository.getOverview(
      userId: userId,
      monthKey: monthKey,
    );
    selectedService = _selectedServiceForOverview(
      overview!,
      resetSelection: resetSelection,
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
    overview = await _ledgerRepository.getOverview(
      userId: userId,
      monthKey: monthKey,
    );
    selectedService = _selectedServiceForOverview(
      overview!,
      resetSelection: resetSelection,
    );
    notifyListeners();
  }

  String _shiftMonth(String key, int delta) {
    final parts = key.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    final shifted = DateTime(year, month + delta);
    return '${shifted.year}-${shifted.month.toString().padLeft(2, '0')}';
  }

  String _monthKeyForDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  LedgerRoute _entryReturnRoute() {
    return switch (entrySource) {
      EntrySource.quickLog => LedgerRoute.quickLog,
      EntrySource.calendar => LedgerRoute.calendar,
    };
  }

  Future<void> _saveEntryForService({
    required HouseholdService service,
    required int day,
    required ServiceEntryStatus status,
    required double quantity,
    required String unit,
    required int rateCents,
    required String note,
  }) async {
    final activeService = selectedService?.id == service.id
        ? selectedService!
        : service;
    final existing = activeService.entries
        .where((entry) => entry.day == day)
        .firstOrNull;
    final amount = calculateEntryAmount(
      service: activeService,
      status: status,
      quantity: quantity,
      rateCents: rateCents,
    ).amountCents;
    final entry =
        existing?.copyWith(
          status: status,
          quantity: quantity,
          unit: unit,
          rateCents: rateCents,
          amountCents: amount,
          note: note,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ) ??
        ServiceEntry(
          id: IdGenerator.create('entry'),
          serviceId: service.id,
          day: day,
          monthKey: monthKey,
          status: status,
          quantity: quantity,
          unit: unit,
          rateCents: rateCents,
          amountCents: amount,
          updatedAt: DateTime.now(),
          note: note,
          pendingSync: true,
        );
    _applyOptimisticEntry(service.id, entry);
    await _ledgerRepository.saveEntry(entry);
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

  double _defaultQuantityFor(
    HouseholdService service,
    ServiceEntryStatus? status,
  ) {
    if (status == ServiceEntryStatus.notDelivered ||
        status == ServiceEntryStatus.noEntry) {
      return 0;
    }
    if (status == ServiceEntryStatus.halfDay) {
      return 0.5;
    }
    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      return 1;
    }
    return service.defaultQuantity;
  }

  int _defaultRateFor(HouseholdService service) {
    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      return _entryValueResolver.fixedDailyRateCents(
        service: service,
        monthKey: monthKey,
      );
    }
    return service.rateCents;
  }

  String _serviceMetricFor(HouseholdService service) {
    final loggedEntries = service.entries
        .where((entry) => entry.status != ServiceEntryStatus.noEntry)
        .toList();
    if (service.templateType == ServiceTemplateType.attendance) {
      final present = loggedEntries
          .where(
            (entry) =>
                entry.status == ServiceEntryStatus.delivered ||
                entry.status == ServiceEntryStatus.rateChanged,
          )
          .length;
      return '$present Present Days';
    }
    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      final delivered = loggedEntries
          .where(
            (entry) =>
                entry.status == ServiceEntryStatus.delivered ||
                entry.status == ServiceEntryStatus.rateChanged,
          )
          .length;
      return '$delivered Delivered Days';
    }
    final total = loggedEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.quantity,
    );
    final formatted = total.toStringAsFixed(
      total.truncateToDouble() == total ? 0 : 1,
    );
    return '$formatted ${service.unit.isEmpty ? 'Units' : service.unit} this month';
  }

  void _setRoute(LedgerRoute nextRoute) {
    isBackwardNavigation = _routeDepth(nextRoute) < _routeDepth(route);
    route = nextRoute;
  }

  int _routeDepth(LedgerRoute route) {
    return switch (route) {
      LedgerRoute.splash => 0,
      LedgerRoute.login ||
      LedgerRoute.register ||
      LedgerRoute.emailVerificationPending ||
      LedgerRoute.forgotPassword ||
      LedgerRoute.resetPasswordOtp => 1,
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
      LedgerRoute.createServiceReview ||
      LedgerRoute.calendar ||
      LedgerRoute.settlementDetail => 4,
      LedgerRoute.entry => 5,
      LedgerRoute.pdfPreview => 6,
    };
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = ErrorMessageMapper.userFacing(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _isLocalDevProfile(UserProfile profile) {
    return profile.id == 'local-user' || profile.id.startsWith('profile_');
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_overviewSubscription?.cancel());
    super.dispose();
  }
}

class AddServiceDraft {
  const AddServiceDraft({
    required this.providerName,
    required this.contactNumber,
    required this.serviceTime,
    required this.remindBeforeMinutes,
    required this.startDate,
    required this.serviceName,
    required this.serviceTemplateName,
    required this.serviceIcon,
    required this.templateType,
    required this.unit,
    required this.defaultQuantity,
    required this.amount,
  });

  final String providerName;
  final String contactNumber;
  final String serviceTime;
  final int remindBeforeMinutes;
  final DateTime startDate;
  final String serviceName;
  final String serviceTemplateName;
  final String serviceIcon;
  final ServiceTemplateType templateType;
  final String unit;
  final double defaultQuantity;
  final double amount;

  factory AddServiceDraft.fromService(HouseholdService service) {
    final fields = _descriptionFields(service.description);
    final startDate = _parseDate(fields['start date']) ?? DateTime.now();
    final amountCents = service.templateType == ServiceTemplateType.fixedMonthly
        ? service.monthlyAmountCents
        : service.rateCents;
    final template = ServiceTemplateCatalog.forService(
      name: service.name,
      icon: service.icon,
      type: service.templateType,
      templateId: fields['template'],
    );
    return AddServiceDraft(
      providerName: fields['provider'] ?? '',
      contactNumber: fields['contact'] ?? '',
      serviceTime: fields['service time'] ?? '',
      remindBeforeMinutes: _parseReminderMinutes(fields['reminder']) ?? 0,
      startDate: startDate,
      serviceName: service.name,
      serviceTemplateName: template.id,
      serviceIcon: service.icon,
      templateType: service.templateType,
      unit: service.unit.isEmpty ? template.defaultUnit : service.unit,
      defaultQuantity: service.defaultQuantity,
      amount: amountCents / 100,
    );
  }

  String get description {
    return [
      'Provider: $providerName',
      'Contact: $contactNumber',
      if (serviceTime.trim().isNotEmpty) 'Service time: $serviceTime',
      'Start date: ${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
      if (remindBeforeMinutes > 0)
        'Reminder: $remindBeforeMinutes minutes before',
      'Template: $serviceTemplateName',
    ].join(' • ');
  }
}

Map<String, String> _descriptionFields(String description) {
  final fields = <String, String>{};
  for (final item in description.split(' • ')) {
    final separator = item.indexOf(':');
    if (separator == -1) {
      continue;
    }
    fields[item.substring(0, separator).trim().toLowerCase()] = item
        .substring(separator + 1)
        .trim();
  }
  return fields;
}

DateTime? _parseDate(String? value) {
  if (value == null) {
    return null;
  }
  final parts = value.split('/');
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  return DateTime(year, month, day);
}

int? _parseReminderMinutes(String? value) {
  if (value == null) {
    return null;
  }
  return int.tryParse(value.split(' ').first);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
