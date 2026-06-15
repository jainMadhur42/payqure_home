import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/app_info/app_version_provider.dart';
import '../../../../core/utils/error_message_mapper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../legal/domain/legal_content.dart';
import '../../data/services/pdf_statement_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/advance_payment.dart';
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
import '../../domain/entities/service_metadata.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/service_template_catalog.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/entry_amount_calculator.dart';
import '../../domain/services/home_summary_builder.dart';
import '../../domain/services/service_start_date_resolver.dart';
import '../../domain/usecases/ledger_calculation_usecases.dart';
import '../analytics/ledger_analytics_mapper.dart';
import '../formatters/entry_feedback_message.dart';
import '../models/add_service_draft.dart';
import '../models/app_toast_event.dart';
import 'entry_operations_controller.dart';
import 'month_data_controller.dart';
import 'payment_operations_controller.dart';
import 'service_reminder_coordinator.dart';
import 'session_controller.dart';

enum EntrySource { quickLog, calendar }

enum PdfSource { serviceDetail, manageService, bills }

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
    AppAnalytics? analytics,
    AppVersionProvider appVersionProvider = const FallbackAppVersionProvider(),
  }) : this._(
         authRepository,
         ledgerRepository,
         pdfStatementService,
         reminderScheduler,
         analytics ?? AppAnalytics.disabled(),
         appVersionProvider,
       );

  LedgerController._(
    AuthRepository authRepository,
    this._ledgerRepository,
    this._pdfStatementService,
    ServiceReminderScheduler reminderScheduler,
    this._analytics,
    this._appVersionProvider,
  ) : _reminderScheduler = reminderScheduler,
      _sessionController = SessionController(authRepository),
      _monthDataController = MonthDataController(_ledgerRepository),
      _entryOperations = EntryOperationsController(_ledgerRepository),
      _paymentOperations = PaymentOperationsController(_ledgerRepository),
      _reminderCoordinator = ServiceReminderCoordinator(reminderScheduler) {
    unawaited(restoreCurrencyPreference());
    unawaited(restoreThemePreference());
    unawaited(_loadAppVersion());
    _authSubscription = _sessionController.watchProfile().listen(
      (nextProfile) => unawaited(_handleProfileChange(nextProfile)),
    );
    _notificationTapSubscription = _reminderScheduler.serviceReminderTaps
        .listen((serviceId) => unawaited(_openServiceFromReminder(serviceId)));
  }

  static String defaultMonthKey() {
    return LedgerMonth.fromDate(DateTime.now()).key;
  }

  final LedgerRepository _ledgerRepository;
  final PdfStatementService _pdfStatementService;
  final ServiceReminderScheduler _reminderScheduler;
  final AppAnalytics _analytics;
  final AppVersionProvider _appVersionProvider;
  final SessionController _sessionController;
  final MonthDataController _monthDataController;
  final EntryOperationsController _entryOperations;
  final PaymentOperationsController _paymentOperations;
  final ServiceReminderCoordinator _reminderCoordinator;
  final LedgerAnalyticsMapper _analyticsMapper = const LedgerAnalyticsMapper();
  final GetServiceTillDateSummaryUseCase _getServiceTillDateSummary =
      const GetServiceTillDateSummaryUseCase();
  final CalculateEntryAmountUseCase _calculateEntryAmount =
      const CalculateEntryAmountUseCase();
  final ServiceStartDateResolver _serviceStartDateResolver =
      const ServiceStartDateResolver();
  final HomeSummaryBuilder _homeSummaryBuilder = const HomeSummaryBuilder();
  StreamSubscription<UserProfile?>? _authSubscription;
  StreamSubscription<String>? _notificationTapSubscription;
  Future<List<HomeServiceSummary>>? _homeSummariesFuture;
  int _homeSummariesRevision = 0;
  int _homeSummariesFutureRevision = -1;
  int _activeOperations = 0;
  int _toastEventId = 0;
  bool _disposed = false;
  String? _pendingReminderServiceId;
  Future<void> _notificationNavigationTail = Future<void>.value();
  AppVersionInfo _appVersionInfo = const AppVersionInfo(
    version: '1.0.0',
    buildNumber: '1',
  );

  LedgerRoute route = LedgerRoute.splash;
  bool isBackwardNavigation = false;
  LedgerOverview? overview;
  UserProfile? profile;
  HouseholdService? selectedService;
  int selectedDay = DateTime.now().day;
  EntrySource entrySource = EntrySource.calendar;
  PdfSource pdfSource = PdfSource.serviceDetail;
  LedgerRoute serviceActionReturnRoute = LedgerRoute.calendar;
  LedgerRoute serviceEditReturnRoute = LedgerRoute.calendar;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  AppToastEvent? toastEvent;
  late String monthKey = defaultMonthKey();
  DateTime quickLogDate = DateTime.now();
  String pendingVerificationEmail = '';
  String pendingPasswordResetEmail = '';
  DateTime? emailVerificationResendAvailableAt;
  AddServiceDraft? addServiceDraft;
  HouseholdService? editingService;

  String get appVersionLabel => _appVersionInfo.label;
  AppCurrency selectedCurrency = AppCurrency.usd;
  final ValueNotifier<ThemeMode> themeModeListenable = ValueNotifier(
    ThemeMode.system,
  );

  bool get isAuthenticated => profile != null;
  bool get isEditingService => editingService != null;
  bool get canResendEmailVerification =>
      emailVerificationResendRemaining == Duration.zero;
  Duration get emailVerificationResendRemaining {
    final availableAt = emailVerificationResendAvailableAt;
    if (availableAt == null) {
      return Duration.zero;
    }
    final remaining = availableAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

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
    _setAnalyticsUserProperties();
  }

  Future<void> _loadAppVersion() async {
    try {
      _appVersionInfo = await _appVersionProvider.load();
      notifyListeners();
    } catch (_) {
      // Keep the fallback label if platform package metadata is unavailable.
    }
  }

  Future<void> completeSplash() async {
    await _run(() async {
      try {
        _pendingReminderServiceId =
            await _reminderScheduler.consumeLaunchServiceId() ??
            _pendingReminderServiceId;
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
      _analytics.logEvent(AnalyticsEvents.onboardingCompleted);
      _setRoute(LedgerRoute.login);
    });
  }

  void trackOnboardingStarted() {
    _analytics.logEvent(AnalyticsEvents.onboardingStarted);
  }

  void trackOnboardingScreenViewed(int index, String screenName) {
    _analytics.logEvent(
      AnalyticsEvents.onboardingScreenViewed,
      parameters: {
        AnalyticsParams.screenIndex: index,
        AnalyticsParams.screenName: _analyticsLabel(screenName),
      },
    );
  }

  void trackOnboardingSkipped(int index, String screenName) {
    _analytics.logEvent(
      AnalyticsEvents.onboardingSkipped,
      parameters: {
        AnalyticsParams.screenIndex: index,
        AnalyticsParams.screenName: _analyticsLabel(screenName),
      },
    );
  }

  Future<void> restoreSession() async {
    await _run(() async {
      _pendingReminderServiceId =
          await _reminderScheduler.consumeLaunchServiceId() ??
          _pendingReminderServiceId;
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

  void _showToast(String message) {
    toastEvent = AppToastEvent(id: ++_toastEventId, message: message);
  }

  void goTo(LedgerRoute nextRoute) {
    _setRoute(nextRoute);
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void goBackTo(LedgerRoute previousRoute) {
    _setRoute(previousRoute);
    isBackwardNavigation = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void reviewAddService(AddServiceDraft draft) {
    addServiceDraft = draft;
    _analytics.logEvent(
      AnalyticsEvents.serviceTemplateSelected,
      parameters: {
        AnalyticsParams.serviceType: _analyticsLabel(draft.serviceIcon),
        AnalyticsParams.templateType: draft.templateType.name,
        AnalyticsParams.unitType: draft.unit,
        AnalyticsParams.currencyCode: selectedCurrency.code,
      },
    );
    _setRoute(LedgerRoute.createServiceReview);
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void startCreateService() {
    editingService = null;
    addServiceDraft = null;
    _analytics.logEvent(AnalyticsEvents.addServiceStarted);
    _setRoute(LedgerRoute.createServiceTemplate);
    notifyListeners();
  }

  void selectServiceTemplate(ServiceTemplateDefinition template) {
    editingService = null;
    addServiceDraft = AddServiceDraft.fromTemplate(template);
    _analytics.logEvent(
      AnalyticsEvents.serviceTemplateSelected,
      parameters: {
        AnalyticsParams.serviceType: _analyticsLabel(template.iconIdentifier),
        AnalyticsParams.templateType: template.templateType.name,
        AnalyticsParams.unitType: template.defaultUnit,
        AnalyticsParams.currencyCode: selectedCurrency.code,
      },
    );
    _setRoute(LedgerRoute.createService);
    notifyListeners();
  }

  void startEditService(
    HouseholdService service, {
    LedgerRoute returnRoute = LedgerRoute.calendar,
  }) {
    editingService = service;
    serviceEditReturnRoute = returnRoute;
    addServiceDraft = AddServiceDraft.fromService(service);
    _setRoute(LedgerRoute.createService);
    isBackwardNavigation = false;
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
        routeAfterSave: serviceEditReturnRoute,
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
      routeAfterSave: LedgerRoute.calendar,
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
      _analytics.logEvent(
        AnalyticsEvents.loginCompleted,
        parameters: const {AnalyticsParams.method: 'email_password'},
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
      _analytics.logEvent(
        AnalyticsEvents.signUpStarted,
        parameters: const {AnalyticsParams.method: 'email_password'},
      );
      profile = await _sessionController.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        privacyPolicyAccepted: privacyPolicyAccepted,
      );
      _analytics.logEvent(
        AnalyticsEvents.signUpCompleted,
        parameters: const {AnalyticsParams.method: 'email_password'},
      );
      pendingVerificationEmail = profile!.email;
      _startEmailVerificationResendCooldown();
      _setRoute(LedgerRoute.emailVerificationPending);
    });
  }

  Future<void> resendEmailVerification() async {
    if (!canResendEmailVerification) {
      errorMessage = 'Please wait before requesting another OTP.';
      notifyListeners();
      return;
    }
    final email = pendingVerificationEmail.isNotEmpty
        ? pendingVerificationEmail
        : profile?.email ?? '';
    if (email.isEmpty) {
      errorMessage = 'Email is not available for this account.';
      notifyListeners();
      return;
    }
    await _run(() async {
      await _sessionController.resendEmailVerification(email);
      _startEmailVerificationResendCooldown();
      successMessage = 'Verification OTP sent again.';
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
      emailVerificationResendAvailableAt = null;
      await _openAuthenticatedDestination(profile!);
    });
  }

  void _startEmailVerificationResendCooldown() {
    emailVerificationResendAvailableAt = DateTime.now().toUtc().add(
      const Duration(minutes: 2),
    );
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

  Future<void> requestPasswordReset(String identifier) async {
    await _run(() async {
      _analytics.logEvent(
        AnalyticsEvents.forgotPasswordStarted,
        parameters: const {AnalyticsParams.method: 'email_password'},
      );
      // A phone identifier is resolved to its account email, where the recovery
      // OTP is sent and against which it must be verified.
      pendingPasswordResetEmail = await _sessionController.requestPasswordReset(
        identifier,
      );
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
      _analytics.logEvent(
        AnalyticsEvents.forgotPasswordCompleted,
        parameters: const {AnalyticsParams.method: 'email_password'},
      );
      pendingPasswordResetEmail = '';
      successMessage = 'Password updated. Sign in with your new password.';
      _setRoute(LedgerRoute.login);
    });
  }

  void selectService(HouseholdService service) {
    selectedService = service;
    selectedDay = _defaultSelectedDayForService(service);
    _setRoute(LedgerRoute.calendar);
    notifyListeners();
  }

  void selectDayForEdit(int day, {EntrySource source = EntrySource.calendar}) {
    selectedDay = day;
    entrySource = source;
    _setRoute(LedgerRoute.entry);
    notifyListeners();
  }

  void customizeEntryForService({
    required HouseholdService service,
    required int day,
    EntrySource source = EntrySource.calendar,
  }) {
    selectedService = service;
    selectedDay = _validEntryDayForService(service, day);
    entrySource = source;
    _setRoute(LedgerRoute.entry);
    notifyListeners();
  }

  void selectDayInline(int day) {
    selectedDay = day;
    final service = selectedService;
    if (service != null) {
      _analytics.logEvent(
        AnalyticsEvents.calendarDateTapped,
        parameters: {
          ..._serviceAnalyticsParameters(service),
          AnalyticsParams.isPastDate: _isPastDay(day),
        },
      );
    }
    notifyListeners();
  }

  void openPdfPreview({PdfSource source = PdfSource.serviceDetail}) {
    pdfSource = source;
    _setRoute(LedgerRoute.pdfPreview);
    notifyListeners();
  }

  void openManageService(HouseholdService service) {
    selectedService = service;
    _setRoute(LedgerRoute.manageService);
    notifyListeners();
  }

  void openSettlementDetail(
    HouseholdService service, {
    LedgerRoute returnRoute = LedgerRoute.calendar,
  }) {
    selectedService = service;
    serviceActionReturnRoute = returnRoute;
    _setRoute(LedgerRoute.settlementDetail);
    notifyListeners();
  }

  void openPaymentHistory(
    HouseholdService service, {
    LedgerRoute returnRoute = LedgerRoute.calendar,
  }) {
    selectedService = service;
    serviceActionReturnRoute = returnRoute;
    _analytics.logEvent(
      AnalyticsEvents.paymentHistoryViewed,
      parameters: _serviceAnalyticsParameters(service),
    );
    _setRoute(LedgerRoute.paymentHistory);
    notifyListeners();
  }

  void openAdvanceHistory(
    HouseholdService service, {
    LedgerRoute returnRoute = LedgerRoute.calendar,
  }) {
    selectedService = service;
    serviceActionReturnRoute = returnRoute;
    _setRoute(LedgerRoute.serviceAdvanceHistory);
    notifyListeners();
  }

  void trackRecordPaymentStarted({
    required HouseholdService service,
    String source = 'service_detail',
  }) {
    _analytics.logEvent(
      AnalyticsEvents.recordPaymentStarted,
      parameters: {
        ..._serviceAnalyticsParameters(service),
        AnalyticsParams.source: source,
        AnalyticsParams.currencyCode: selectedCurrency.code,
      },
    );
  }

  Future<void> openQuickLog({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    quickLogDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    _analytics.logEvent(
      AnalyticsEvents.quickLogOpened,
      parameters: {
        AnalyticsParams.entrySource: date == null ? 'quick_log' : 'past_date',
        AnalyticsParams.isPastDate: _isPastDate(quickLogDate),
      },
    );
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
      _showToast('Profile updated successfully.');
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
      _analytics.logEvent(
        AnalyticsEvents.serviceCreated,
        parameters: _serviceAnalyticsParameters(selectedService!),
      );
      _setAnalyticsUserProperties();
      _showToast('$name service added successfully.');
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
      _analytics.logEvent(
        AnalyticsEvents.serviceUpdated,
        parameters: _serviceAnalyticsParameters(selectedService!),
      );
      _setAnalyticsUserProperties();
      final userId = profile?.id ?? overview?.profile.id;
      if (userId != null) {
        await _startLedger(userId, resetSelection: false);
      }
      _showToast('$name service updated successfully.');
      _setRoute(routeAfterSave);
    });
  }

  Future<void> updateServiceReminder({
    required HouseholdService service,
    required String serviceTime,
    required int remindBeforeMinutes,
  }) async {
    await _run(() async {
      final metadata = ServiceMetadata.parse(service.description);
      final updatedMetadata = metadata.copyWith(
        serviceTime: serviceTime.trim(),
        remindBeforeMinutes: remindBeforeMinutes,
      );
      final startMonthKey = updatedMetadata.startDate == null
          ? service.monthKey
          : _monthKeyForDate(updatedMetadata.startDate!);
      final updated = await _ledgerRepository.updateService(
        id: service.id,
        monthKey: startMonthKey,
        name: service.name,
        description: updatedMetadata.encode(),
        unit: service.unit,
        defaultQuantity: service.defaultQuantity,
        rateCents: service.rateCents,
        monthlyAmountCents: service.monthlyAmountCents,
      );
      _applyOptimisticService(updated);
      await _configureServiceReminders(
        overview?.services ?? [updated],
        requestPermission: remindBeforeMinutes > 0,
        force: true,
      );
      _showToast(
        remindBeforeMinutes > 0
            ? '${service.name} reminder updated.'
            : '${service.name} reminder turned off.',
      );
    });
  }

  Future<void> deleteService(HouseholdService service) async {
    await _run(() async {
      await _ledgerRepository.deleteService(
        serviceId: service.id,
        monthKey: monthKey,
      );
      _analytics.logEvent(
        AnalyticsEvents.serviceDeleted,
        parameters: _serviceAnalyticsParameters(service),
      );
      selectedService = null;
      addServiceDraft = null;
      editingService = null;
      final userId = profile?.id ?? overview?.profile.id;
      if (userId != null) {
        await _startLedger(userId, resetSelection: true);
      }
      _setAnalyticsUserProperties();
      _showToast('${service.name} service deleted successfully.');
      _setRoute(LedgerRoute.dashboard);
    });
  }

  Future<ServiceEntry?> saveSelectedEntry({
    required ServiceEntryStatus status,
    required double quantity,
    required String unit,
    required int rateCents,
    required String note,
  }) async {
    final service = selectedService;
    if (service == null) {
      return null;
    }
    ServiceEntry? savedEntry;
    await _run(() async {
      final entry = await _entryOperations.save(
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
      savedEntry = entry;
      _logEntrySaved(entry, service: service, source: entrySource.name);
      await _refreshLedgerState(resetSelection: false);
      _showToast(
        EntryFeedbackMessage.customized(
          day: selectedDay,
          monthKey: monthKey,
          entry: entry,
          templateType: service.templateType,
        ),
      );
      _setRoute(_entryReturnRoute());
    });
    return errorMessage == null ? savedEntry : null;
  }

  Future<void> saveDefaultEntryForService({
    required HouseholdService service,
    required int day,
    ServiceEntryStatus? status,
  }) async {
    await _run(() async {
      final entry = await _entryOperations.saveDefault(
        service: service,
        monthKey: monthKey,
        day: day,
        status: status,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      _logEntrySaved(entry, service: service, source: 'calendar');
      await _refreshLedgerState(resetSelection: false);
      _showToast(
        EntryFeedbackMessage.statusUpdated(
          day: day,
          monthKey: monthKey,
          status: entry.status,
          templateType: service.templateType,
        ),
      );
    });
  }

  Future<ServiceEntry?> saveQuickEntryForService({
    required HouseholdService service,
    required int day,
    required ServiceEntryStatus status,
  }) async {
    errorMessage = null;
    try {
      final entry = await _entryOperations.saveDefault(
        service: service,
        monthKey: monthKey,
        day: day,
        status: status,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      _logEntrySaved(entry, service: service, source: 'quick_log');
      await _refreshLedgerState(resetSelection: false);
      _showToast(
        EntryFeedbackMessage.statusUpdated(
          day: day,
          monthKey: monthKey,
          status: entry.status,
          templateType: service.templateType,
        ),
      );
      notifyListeners();
      return entry;
    } catch (error) {
      errorMessage = ErrorMessageMapper.userFacing(error);
      notifyListeners();
      return null;
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
      final entry = await _entryOperations.clear(
        service: service,
        monthKey: monthKey,
        day: day,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      _analytics.logEvent(
        AnalyticsEvents.entryDeleted,
        parameters: _entryAnalyticsParameters(
          entry,
          service: service,
          source: 'quick_log',
        ),
      );
      await _refreshLedgerState(resetSelection: false);
      _showToast('$day entry cleared successfully.');
      notifyListeners();
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
        final entry = await _entryOperations.saveDefault(
          service: service,
          monthKey: monthKey,
          day: day,
          status: ServiceEntryStatus.delivered,
          onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
        );
        _logEntrySaved(entry, service: service, source: 'quick_log');
      }
      _analytics.logEvent(
        AnalyticsEvents.quickLogCompleted,
        parameters: {
          AnalyticsParams.serviceCount: services.length,
          AnalyticsParams.entrySource: 'quick_log',
        },
      );
      await _refreshLedgerState(resetSelection: false);
      _showToast(
        '${services.length} service entr${services.length == 1 ? 'y' : 'ies'} '
        'updated successfully.',
      );
    });
  }

  Future<void> clearEntryForService({
    required HouseholdService service,
    required int day,
  }) async {
    await _run(() async {
      final entry = await _entryOperations.clear(
        service: service,
        monthKey: monthKey,
        day: day,
        onPrepared: (entry) => _applyOptimisticEntry(service.id, entry),
      );
      _analytics.logEvent(
        AnalyticsEvents.entryDeleted,
        parameters: _entryAnalyticsParameters(
          entry,
          service: service,
          source: 'calendar',
        ),
      );
      await _refreshLedgerState(resetSelection: false);
      _showToast('$day entry cleared successfully.');
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
      _analytics.logEvent(
        AnalyticsEvents.advanceAdded,
        parameters: {
          ..._serviceAnalyticsParameters(service),
          AnalyticsParams.amountBucket: AmountAnalyticsHelper.centsBucket(
            amountCents,
          ),
          AnalyticsParams.currencyCode: selectedCurrency.code,
        },
      );
      _invalidateHomeSummaries();
      _showToast('Advance added successfully.');
    });
  }

  Future<void> updateAdvance({
    required AdvancePayment advance,
    required int amountCents,
    required DateTime paidOn,
    String note = '',
  }) async {
    await _run(() async {
      await _paymentOperations.updateAdvance(
        advance: advance,
        amountCents: amountCents,
        paidOn: paidOn,
        note: note,
      );
      _invalidateHomeSummaries();
      _showToast('Advance updated successfully.');
    });
  }

  Future<void> deleteAdvance(AdvancePayment advance) async {
    await _run(() async {
      await _paymentOperations.deleteAdvance(advance);
      _invalidateHomeSummaries();
      _showToast('Advance deleted successfully.');
    });
  }

  Future<void> savePayment({
    required int amountCents,
    required DateTime paymentDate,
    required PaymentMode mode,
    String note = '',
    String source = 'service_detail',
    LedgerRoute returnRoute = LedgerRoute.calendar,
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
      _analytics.logEvent(
        AnalyticsEvents.paymentRecorded,
        parameters: _paymentAnalyticsParameters(
          service,
          amountCents: amountCents,
          mode: mode,
          source: source,
        ),
      );
      _invalidateHomeSummaries();
      successMessage = 'Payment recorded.';
      _showToast('Payment recorded successfully.');
      _setRoute(returnRoute);
    });
  }

  Future<void> updatePayment({
    required PaymentTransaction payment,
    required int amountCents,
    required DateTime paymentDate,
    required PaymentMode mode,
    HouseholdService? service,
    String source = 'payment_history',
    LedgerRoute returnRoute = LedgerRoute.paymentHistory,
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
      final analyticsService = service ?? selectedService;
      if (analyticsService != null) {
        _analytics.logEvent(
          AnalyticsEvents.paymentUpdated,
          parameters: _paymentAnalyticsParameters(
            analyticsService,
            amountCents: amountCents,
            mode: mode,
            source: source,
          ),
        );
      }
      _invalidateHomeSummaries();
      successMessage = 'Payment updated.';
      _showToast('Payment updated successfully.');
      _setRoute(returnRoute);
    });
  }

  Future<void> deletePayment(
    PaymentTransaction payment, {
    HouseholdService? service,
    String source = 'payment_history',
    LedgerRoute returnRoute = LedgerRoute.paymentHistory,
  }) async {
    await _run(() async {
      await _paymentOperations.deletePayment(payment);
      final analyticsService = service ?? selectedService;
      if (analyticsService != null) {
        _analytics.logEvent(
          AnalyticsEvents.paymentDeleted,
          parameters: _paymentAnalyticsParameters(
            analyticsService,
            amountCents: payment.amountCents,
            mode: payment.mode,
            source: source,
          ),
        );
      }
      _invalidateHomeSummaries();
      successMessage = 'Payment deleted.';
      _showToast('Payment deleted successfully.');
      _setRoute(returnRoute);
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

  Future<List<ServiceHistoryItem>> loadSelectedAdvanceHistory() async {
    final service = selectedService;
    if (service == null) {
      return const [];
    }
    return _paymentOperations.serviceAdvanceHistory(service);
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
    _analytics.logEvent(
      AnalyticsEvents.pdfGenerateStarted,
      parameters: _pdfAnalyticsParameters(bill.service),
    );
    try {
      final bytes = await _pdfStatementService.buildStatement(bill);
      _analytics.logEvent(
        AnalyticsEvents.pdfGenerated,
        parameters: _pdfAnalyticsParameters(bill.service),
      );
      return bytes;
    } catch (error, stackTrace) {
      _analytics.logEvent(
        AnalyticsEvents.pdfGenerationFailed,
        parameters: _pdfAnalyticsParameters(bill.service),
      );
      _analytics.logErrorContext(
        error,
        stackTrace: stackTrace,
        reason: AnalyticsEvents.pdfGenerationFailed,
        keys: _pdfAnalyticsParameters(bill.service),
      );
      rethrow;
    }
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
      await _reminderCoordinator.reset();
      await _sessionController.signOut();
      profile = null;
      overview = null;
      selectedService = null;
      _setRoute(LedgerRoute.login);
    });
  }

  Future<void> ensureHomeNotificationsConfigured() async {
    final currentOverview = overview;
    if (currentOverview == null) {
      return;
    }
    await _configureServiceReminders(
      currentOverview.services,
      requestPermission: true,
    );
  }

  Future<void> restoreServiceReminders({bool force = false}) async {
    final currentOverview = overview;
    if (currentOverview == null) {
      return;
    }
    await _configureServiceReminders(
      currentOverview.services,
      requestPermission: false,
      force: force,
    );
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
    _setAnalyticsUserProperties();
    if (route != LedgerRoute.calendar) {
      _setRoute(LedgerRoute.dashboard);
    }
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
        _openPendingReminderServiceIfPossible(nextOverview);
        resetSelection = false;
        _invalidateHomeSummaries();
        _setAnalyticsUserProperties();
        unawaited(restoreServiceReminders());
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
        selectedDay = _defaultSelectedDayForMonth(nextMonthKey);
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
        _openPendingReminderServiceIfPossible(nextOverview);
        resetSelection = false;
        _invalidateHomeSummaries();
        _setAnalyticsUserProperties();
        unawaited(restoreServiceReminders());
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

  Future<void> _openServiceFromReminder(String serviceId) {
    _pendingReminderServiceId = serviceId;
    final operation = _notificationNavigationTail.then(
      (_) => _navigateToReminderService(),
    );
    _notificationNavigationTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _navigateToReminderService() async {
    final serviceId = _pendingReminderServiceId;
    if (serviceId == null || profile == null) {
      return;
    }

    final currentMonthKey = defaultMonthKey();
    if (monthKey != currentMonthKey) {
      final loaded = await _loadMonth(
        userId: profile!.id,
        nextMonthKey: currentMonthKey,
      );
      if (!loaded || _pendingReminderServiceId != serviceId) {
        return;
      }
    }

    final currentOverview = overview;
    if (currentOverview == null) {
      return;
    }
    _openPendingReminderServiceIfPossible(currentOverview);
    notifyListeners();
  }

  void _openPendingReminderServiceIfPossible(LedgerOverview currentOverview) {
    final serviceId = _pendingReminderServiceId;
    if (serviceId == null) {
      return;
    }
    final matches = currentOverview.services.where(
      (service) => service.id == serviceId,
    );
    if (matches.isEmpty) {
      return;
    }
    final service = matches.first;
    selectedService = service;
    selectedDay = _defaultSelectedDayForService(service);
    _pendingReminderServiceId = null;
    _setRoute(LedgerRoute.calendar);
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
    _openPendingReminderServiceIfPossible(overview!);
    _invalidateHomeSummaries();
    notifyListeners();
  }

  Future<void> _configureServiceReminders(
    List<HouseholdService> services, {
    required bool requestPermission,
    bool force = false,
  }) async {
    try {
      await _reminderCoordinator.configure(
        services,
        requestPermission: requestPermission,
        force: force,
      );
    } catch (error, stackTrace) {
      _analytics.logErrorContext(
        error,
        stackTrace: stackTrace,
        reason: 'service_reminder_configuration_failed',
        keys: const {AnalyticsParams.screenName: 'home'},
      );
    }
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

  void _applyOptimisticService(HouseholdService updated) {
    if (selectedService?.id == updated.id) {
      selectedService = updated.copyWith(
        monthKey: monthKey,
        entries: selectedService?.entries ?? updated.entries,
      );
    }
    final currentOverview = overview;
    if (currentOverview != null) {
      final services = currentOverview.services
          .map(
            (service) => service.id == updated.id
                ? updated.copyWith(
                    monthKey: currentOverview.monthKey,
                    entries: service.entries,
                  )
                : service,
          )
          .toList(growable: false);
      overview = LedgerOverview(
        profile: currentOverview.profile,
        monthKey: currentOverview.monthKey,
        monthLabel: currentOverview.monthLabel,
        services: services,
        totalPayableCents: currentOverview.totalPayableCents,
        advancePaidCents: currentOverview.advancePaidCents,
      );
    }
    _invalidateHomeSummaries();
    notifyListeners();
  }

  void _invalidateHomeSummaries() {
    _homeSummariesRevision++;
    _homeSummariesFuture = null;
  }

  void _setRoute(LedgerRoute nextRoute) {
    isBackwardNavigation = _routeDepth(nextRoute) < _routeDepth(route);
    route = nextRoute;
    _analytics.logScreenView(_screenNameForRoute(nextRoute));
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
      LedgerRoute.contributionStats ||
      LedgerRoute.quickLog ||
      LedgerRoute.createServiceTemplate ||
      LedgerRoute.createService ||
      LedgerRoute.globalPaymentHistory ||
      LedgerRoute.advanceHistory ||
      LedgerRoute.contacts ||
      LedgerRoute.profile ||
      LedgerRoute.currency ||
      LedgerRoute.theme ||
      LedgerRoute.notifications => 3,
      LedgerRoute.privacyPolicy ||
      LedgerRoute.termsDisclaimer ||
      LedgerRoute.deleteMyData => 3,
      LedgerRoute.createServiceReview || LedgerRoute.calendar => 4,
      LedgerRoute.manageService => 5,
      LedgerRoute.entry ||
      LedgerRoute.settlementDetail ||
      LedgerRoute.paymentHistory ||
      LedgerRoute.serviceAdvanceHistory => 6,
      LedgerRoute.pdfPreview => 7,
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

  void _logEntrySaved(
    ServiceEntry entry, {
    required HouseholdService service,
    required String source,
  }) {
    final existing = service.entries.any(
      (candidate) =>
          candidate.day == entry.day && candidate.monthKey == entry.monthKey,
    );
    _analytics.logEvent(
      existing ? AnalyticsEvents.entryUpdated : AnalyticsEvents.entryCreated,
      parameters: _entryAnalyticsParameters(
        entry,
        service: service,
        source: source,
      ),
    );
  }

  Map<String, Object?> _serviceAnalyticsParameters(HouseholdService service) {
    return _analyticsMapper.serviceParameters(
      service: service,
      currency: selectedCurrency,
    );
  }

  Map<String, Object?> _entryAnalyticsParameters(
    ServiceEntry entry, {
    required HouseholdService service,
    required String source,
  }) {
    return _analyticsMapper.entryParameters(
      entry: entry,
      service: service,
      source: source,
      monthKey: monthKey,
      currency: selectedCurrency,
    );
  }

  Map<String, Object?> _paymentAnalyticsParameters(
    HouseholdService service, {
    required int amountCents,
    required PaymentMode mode,
    required String source,
  }) {
    final dueCents = selectedService?.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.amountCents,
    );
    return _analyticsMapper.paymentParameters(
      service: service,
      amountCents: amountCents,
      paymentMode: mode.name,
      source: source,
      dueCents: dueCents ?? 0,
      currency: selectedCurrency,
    );
  }

  Map<String, Object?> _pdfAnalyticsParameters(HouseholdService service) {
    return _analyticsMapper.pdfParameters(
      service: service,
      monthKey: monthKey,
      currency: selectedCurrency,
    );
  }

  void _setAnalyticsUserProperties() {
    final services = overview?.services ?? const <HouseholdService>[];
    _analytics.setUserProperties(
      _analyticsMapper.userProperties(
        services: services,
        currency: selectedCurrency,
        appVersion: _appVersionInfo,
      ),
    );
  }

  bool _isPastDay(int day) {
    return _analyticsMapper.isPastDay(monthKey: monthKey, day: day);
  }

  int _validEntryDayForService(HouseholdService service, int day) {
    final startDate = _serviceStartDateResolver.resolve(service);
    final selectedMonth = _dateForMonthKey(monthKey);
    if (startDate != null &&
        startDate.year == selectedMonth.year &&
        startDate.month == selectedMonth.month &&
        day < startDate.day) {
      return startDate.day;
    }
    return day;
  }

  int _defaultSelectedDayForService(HouseholdService service) {
    return _validEntryDayForService(
      service,
      _defaultSelectedDayForMonth(monthKey),
    );
  }

  int _defaultSelectedDayForMonth(String targetMonthKey) {
    final selectedMonth = _dateForMonthKey(targetMonthKey);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final targetMonth = DateTime(selectedMonth.year, selectedMonth.month);

    if (targetMonth == currentMonth) {
      return now.day;
    }
    if (targetMonth.isBefore(currentMonth)) {
      return DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    }
    return 1;
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  String _analyticsLabel(String value) {
    return _analyticsMapper.analyticsLabel(value);
  }

  String _screenNameForRoute(LedgerRoute route) {
    return _analyticsMapper.screenName(route);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    unawaited(_notificationTapSubscription?.cancel());
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
