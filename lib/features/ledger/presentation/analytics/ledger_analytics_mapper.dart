import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/app_info/app_version_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

class LedgerAnalyticsMapper {
  const LedgerAnalyticsMapper();

  Map<String, Object?> serviceParameters({
    required HouseholdService service,
    required AppCurrency currency,
  }) {
    final base = <String, Object?>{
      AnalyticsParams.serviceType: safeServiceType(service),
      AnalyticsParams.templateType: service.templateType.name,
      AnalyticsParams.serviceNature: serviceNature(service.templateType),
      AnalyticsParams.unitType: analyticsLabel(service.unit),
      AnalyticsParams.currencyCode: currency.code,
      AnalyticsParams.autoMarkEnabled: false,
      AnalyticsParams.defaultQuantity: service.defaultQuantity,
    };
    return switch (service.templateType) {
      ServiceTemplateType.quantity => {
        ...base,
        AnalyticsParams.unitPriceBucket: AmountAnalyticsHelper.centsBucket(
          service.rateCents,
        ),
      },
      ServiceTemplateType.attendance => {
        ...base,
        AnalyticsParams.monthlyAmountBucket: AmountAnalyticsHelper.centsBucket(
          _attendanceMonthlyAmountCents(service),
        ),
        AnalyticsParams.allowHalfDay: true,
      },
      ServiceTemplateType.fixedMonthly => {
        ...base,
        AnalyticsParams.monthlyAmountBucket: AmountAnalyticsHelper.centsBucket(
          service.monthlyAmountCents,
        ),
      },
    };
  }

  Map<String, Object?> entryParameters({
    required ServiceEntry entry,
    required HouseholdService service,
    required String source,
    required String monthKey,
    required AppCurrency currency,
    DateTime? today,
  }) {
    final base = <String, Object?>{
      ...serviceParameters(service: service, currency: currency),
      AnalyticsParams.entryStatus: entryStatusLabel(
        entry.status,
        service.templateType,
      ),
      AnalyticsParams.entrySource: source,
      AnalyticsParams.isPastDate: isPastDay(
        monthKey: monthKey,
        day: entry.day,
        today: today,
      ),
      AnalyticsParams.dateRelation: dateRelation(
        monthKey: monthKey,
        day: entry.day,
        today: today,
      ),
      AnalyticsParams.quantityBucket: AmountAnalyticsHelper.getQuantityBucket(
        entry.quantity,
      ),
      AnalyticsParams.quantityChanged:
          entry.quantity != service.defaultQuantity &&
          entry.status != ServiceEntryStatus.notDelivered &&
          entry.status != ServiceEntryStatus.noEntry,
      AnalyticsParams.rateChanged:
          entry.rateCents != service.rateCents &&
          service.templateType != ServiceTemplateType.fixedMonthly,
      AnalyticsParams.entryAmountBucket: AmountAnalyticsHelper.centsBucket(
        entry.amountCents,
      ),
    };
    if (service.templateType == ServiceTemplateType.quantity) {
      return {
        ...base,
        AnalyticsParams.unitPriceBucket: AmountAnalyticsHelper.centsBucket(
          entry.rateCents,
        ),
      };
    }
    if (service.templateType == ServiceTemplateType.attendance) {
      return {
        ...base,
        AnalyticsParams.monthlyAmountBucket: AmountAnalyticsHelper.centsBucket(
          _attendanceMonthlyAmountCents(service),
        ),
      };
    }
    return base;
  }

  Map<String, Object?> paymentParameters({
    required HouseholdService service,
    required int amountCents,
    required String paymentMode,
    required String source,
    required int dueCents,
    required AppCurrency currency,
  }) {
    return {
      ...serviceParameters(service: service, currency: currency),
      AnalyticsParams.paymentMode: paymentMode,
      AnalyticsParams.paymentResult: paymentResult(
        amountCents: amountCents,
        dueCents: dueCents,
      ),
      AnalyticsParams.source: source,
      AnalyticsParams.amountBucket: AmountAnalyticsHelper.centsBucket(
        amountCents,
      ),
      AnalyticsParams.paymentType: 'payment',
      AnalyticsParams.currencyCode: currency.code,
    };
  }

  Map<String, Object?> pdfParameters({
    required HouseholdService service,
    required String monthKey,
    required AppCurrency currency,
    DateTime? today,
  }) {
    return {
      ...serviceParameters(service: service, currency: currency),
      AnalyticsParams.monthType: monthType(monthKey, today: today),
      AnalyticsParams.monthOffset: monthOffset(monthKey, today: today),
      AnalyticsParams.currencyCode: currency.code,
    };
  }

  Map<String, Object?> userProperties({
    required List<HouseholdService> services,
    required AppCurrency currency,
    required AppVersionInfo appVersion,
  }) {
    return {
      AnalyticsParams.serviceCount: services.length,
      AnalyticsParams.serviceCountBucket: AmountAnalyticsHelper.getCountBucket(
        services.length,
      ),
      AnalyticsParams.hasCreatedService: services.isNotEmpty,
      AnalyticsParams.hasLoggedEntry: services.any(
        (service) => service.entries.isNotEmpty,
      ),
      AnalyticsParams.preferredServiceType: preferredServiceType(services),
      AnalyticsParams.hasQuantityService: services.any(
        (service) => service.templateType == ServiceTemplateType.quantity,
      ),
      AnalyticsParams.hasAttendanceService: services.any(
        (service) => service.templateType == ServiceTemplateType.attendance,
      ),
      AnalyticsParams.hasFixedMonthlyService: services.any(
        (service) => service.templateType == ServiceTemplateType.fixedMonthly,
      ),
      AnalyticsParams.currencyCode: currency.code,
      AnalyticsParams.countryCode: countryCodeForCurrency(currency),
      AnalyticsParams.appLanguage: 'en',
      AnalyticsParams.signupMethod: 'email_password',
      AnalyticsParams.appVersion:
          '${appVersion.version}+${appVersion.buildNumber}',
    };
  }

  bool isPastDay({
    required String monthKey,
    required int day,
    DateTime? today,
  }) {
    final month = LedgerMonth.parse(monthKey);
    final current = today ?? DateTime.now();
    final currentDay = DateTime(current.year, current.month, current.day);
    return DateTime(month.year, month.month, day).isBefore(currentDay);
  }

  String dateRelation({
    required String monthKey,
    required int day,
    DateTime? today,
  }) {
    final month = LedgerMonth.parse(monthKey);
    final current = today ?? DateTime.now();
    final selected = DateTime(month.year, month.month, day);
    final currentDay = DateTime(current.year, current.month, current.day);
    if (selected == currentDay) return 'today';
    return selected.isBefore(currentDay) ? 'past' : 'future';
  }

  int monthOffset(String monthKey, {DateTime? today}) {
    final month = LedgerMonth.parse(monthKey);
    final current = today ?? DateTime.now();
    return (month.year - current.year) * 12 + month.month - current.month;
  }

  String monthType(String monthKey, {DateTime? today}) {
    final month = LedgerMonth.parse(monthKey);
    final current = today ?? DateTime.now();
    final selected = DateTime(month.year, month.month);
    final currentMonth = DateTime(current.year, current.month);
    if (selected == currentMonth) {
      return 'current';
    }
    return selected.isBefore(currentMonth) ? 'past' : 'future';
  }

  String paymentResult({required int amountCents, required int dueCents}) {
    if (dueCents == 0 || amountCents == dueCents) {
      return 'paid';
    }
    return amountCents < dueCents ? 'partial' : 'overpaid';
  }

  String serviceNature(ServiceTemplateType type) {
    return switch (type) {
      ServiceTemplateType.quantity => 'quantity_based',
      ServiceTemplateType.attendance => 'attendance_based',
      ServiceTemplateType.fixedMonthly => 'fixed_monthly',
    };
  }

  String entryStatusLabel(
    ServiceEntryStatus status,
    ServiceTemplateType templateType,
  ) {
    return switch ((templateType, status)) {
      (_, ServiceEntryStatus.noEntry) => 'not_logged',
      (ServiceTemplateType.attendance, ServiceEntryStatus.delivered) =>
        'present',
      (ServiceTemplateType.attendance, ServiceEntryStatus.notDelivered) =>
        'absent',
      (ServiceTemplateType.attendance, ServiceEntryStatus.halfDay) =>
        'half_day',
      (_, ServiceEntryStatus.notDelivered) => 'missed',
      _ => 'logged',
    };
  }

  String safeServiceType(HouseholdService service) {
    final value = service.icon.trim().isNotEmpty
        ? service.icon.trim()
        : service.templateType.name;
    return analyticsLabel(value);
  }

  String analyticsLabel(String value) {
    return value
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
  }

  String countryCodeForCurrency(AppCurrency currency) {
    return switch (currency.code) {
      'INR' => 'IN',
      'USD' => 'US',
      'GBP' => 'GB',
      'AED' => 'AE',
      'AUD' => 'AU',
      'CAD' => 'CA',
      'SGD' => 'SG',
      _ => '',
    };
  }

  String preferredServiceType(List<HouseholdService> services) {
    if (services.isEmpty) return 'none';
    final counts = <String, int>{};
    for (final service in services) {
      final type = safeServiceType(service);
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String screenName(LedgerRoute route) {
    return switch (route) {
      LedgerRoute.splash => 'splash',
      LedgerRoute.onboarding => 'onboarding_screen',
      LedgerRoute.login => 'login_screen',
      LedgerRoute.register => 'signup_screen',
      LedgerRoute.emailVerificationPending => 'email_verification_pending',
      LedgerRoute.forgotPassword => 'forgot_password',
      LedgerRoute.resetPasswordOtp => 'reset_password_otp',
      LedgerRoute.dashboard => 'home_screen',
      LedgerRoute.contributionStats => 'spending_stats',
      LedgerRoute.quickLog => 'quick_log_screen',
      LedgerRoute.createServiceTemplate => 'service_template_picker',
      LedgerRoute.createService => 'add_service_screen',
      LedgerRoute.calendar => 'service_detail_screen',
      LedgerRoute.manageService => 'manage_service',
      LedgerRoute.entry => 'add_entry_screen',
      LedgerRoute.settlementDetail => 'billing_summary_screen',
      LedgerRoute.paymentHistory ||
      LedgerRoute.globalPaymentHistory => 'payment_history_screen',
      LedgerRoute.advanceHistory => 'advance_history',
      LedgerRoute.serviceAdvanceHistory => 'service_advance_history',
      LedgerRoute.pdfPreview => 'pdf_preview_screen',
      LedgerRoute.contacts => 'contacts_screen',
      LedgerRoute.more => 'more_screen',
      LedgerRoute.profile => 'profile_screen',
      LedgerRoute.currency => 'currency_picker',
      LedgerRoute.theme => 'theme_picker',
      LedgerRoute.accentColor => 'accent_color_picker',
      LedgerRoute.notifications => 'notifications',
      LedgerRoute.privacyPolicy => 'privacy_policy',
      LedgerRoute.termsDisclaimer => 'terms_disclaimer',
      LedgerRoute.deleteMyData => 'delete_my_data',
      LedgerRoute.privacyPolicyAcceptance => 'privacy_policy_acceptance',
      LedgerRoute.appUpdateRequired => 'app_update_required',
    };
  }

  int _attendanceMonthlyAmountCents(HouseholdService service) {
    return service.monthlyAmountCents > 0
        ? service.monthlyAmountCents
        : service.rateCents;
  }
}
