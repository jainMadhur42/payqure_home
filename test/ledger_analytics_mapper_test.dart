import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/analytics/app_analytics.dart';
import 'package:payqure_home/core/app_info/app_version_provider.dart';
import 'package:payqure_home/core/utils/currency_formatter.dart';
import 'package:payqure_home/features/ledger/domain/entities/app_route.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/presentation/analytics/ledger_analytics_mapper.dart';

void main() {
  const mapper = LedgerAnalyticsMapper();
  final service = HouseholdService(
    id: 'service',
    userId: 'user',
    name: 'Milkman',
    description: '',
    icon: 'Milk Delivery',
    templateType: ServiceTemplateType.quantity,
    monthKey: '2026-06',
    unit: 'L',
    defaultQuantity: 1,
    rateCents: 6000,
    monthlyAmountCents: 0,
    entries: const [],
    updatedAt: DateTime(2026, 6),
  );

  test('service parameters contain normalized non-PII pricing context', () {
    final parameters = mapper.serviceParameters(
      service: service,
      currency: AppCurrency.values[1],
    );

    expect(parameters[AnalyticsParams.serviceType], 'milk_delivery');
    expect(parameters[AnalyticsParams.templateType], 'quantity');
    expect(parameters[AnalyticsParams.unitPrice], 60);
    expect(parameters[AnalyticsParams.unitPriceBucket], '1_100');
    expect(parameters[AnalyticsParams.currencyCode], 'INR');
  });

  test('entry parameters detect quantity and rate changes by date', () {
    final entry = ServiceEntry(
      id: 'entry',
      serviceId: service.id,
      day: 5,
      monthKey: '2026-06',
      status: ServiceEntryStatus.delivered,
      quantity: 1.5,
      unit: 'L',
      rateCents: 6500,
      amountCents: 9750,
      updatedAt: DateTime(2026, 6, 5),
    );

    final parameters = mapper.entryParameters(
      entry: entry,
      service: service,
      source: 'calendar',
      monthKey: '2026-06',
      currency: AppCurrency.values[1],
      today: DateTime(2026, 6, 12),
    );

    expect(parameters[AnalyticsParams.isPastDate], isTrue);
    expect(parameters[AnalyticsParams.quantityChanged], isTrue);
    expect(parameters[AnalyticsParams.rateChanged], isTrue);
    expect(parameters[AnalyticsParams.entryAmountBucket], '1_100');
  });

  test('payment result and month type preserve analytics semantics', () {
    expect(mapper.paymentResult(amountCents: 5000, dueCents: 10000), 'partial');
    expect(mapper.paymentResult(amountCents: 10000, dueCents: 10000), 'paid');
    expect(
      mapper.paymentResult(amountCents: 12000, dueCents: 10000),
      'overpaid',
    );
    expect(mapper.monthType('2026-05', today: DateTime(2026, 6, 12)), 'past');
    expect(
      mapper.monthType('2026-06', today: DateTime(2026, 6, 12)),
      'current',
    );
    expect(mapper.monthType('2026-07', today: DateTime(2026, 6, 12)), 'future');
  });

  test('user properties and screen names remain centralized', () {
    final properties = mapper.userProperties(
      services: [service],
      currency: AppCurrency.values[1],
      appVersion: const AppVersionInfo(version: '2.0.0', buildNumber: '42'),
    );

    expect(properties[AnalyticsParams.serviceCount], 1);
    expect(properties[AnalyticsParams.hasQuantityService], isTrue);
    expect(properties[AnalyticsParams.countryCode], 'IN');
    expect(properties[AnalyticsParams.appVersion], '2.0.0+42');
    expect(mapper.screenName(LedgerRoute.dashboard), 'home');
    expect(mapper.screenName(LedgerRoute.calendar), 'service_detail');
  });
}
