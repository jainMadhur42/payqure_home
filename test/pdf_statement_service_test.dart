import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/household_service.dart';
import 'package:payqure_home/features/ledger/domain/entities/monthly_bill.dart';
import 'package:payqure_home/features/ledger/domain/entities/monthly_settlement.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_entry.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('statement is generated as exactly one PDF page', () async {
    final now = DateTime(2026, 6, 6);
    final entries = List.generate(
      14,
      (index) => ServiceEntry(
        id: 'entry-$index',
        serviceId: 'service-1',
        day: index + 1,
        monthKey: '2026-06',
        status: ServiceEntryStatus.delivered,
        quantity: index == 5 ? 2 : 1,
        unit: 'Day',
        rateCents: 1000,
        amountCents: 1000,
        note: index == 0 ? 'Started service this month.' : '',
        updatedAt: now,
      ),
    );
    final service = HouseholdService(
      id: 'service-1',
      userId: 'user-1',
      name: 'Car Wash',
      description: 'Provider: Vishal',
      icon: 'car',
      templateType: ServiceTemplateType.fixedMonthly,
      monthKey: '2026-06',
      unit: 'Month',
      defaultQuantity: 1,
      rateCents: 0,
      monthlyAmountCents: 14000,
      entries: entries,
      updatedAt: now,
    );
    final settlement = MonthlySettlement(
      id: 'settlement-1',
      userId: 'user-1',
      serviceId: service.id,
      monthKey: '2026-06',
      grossAmountCents: 14000,
      advanceUsedCents: 0,
      previousCarryForwardCents: 15800,
      previousAdvanceCents: 0,
      payableAmountCents: 29800,
      paidAmountCents: 0,
      remainingAmountCents: 29800,
      carryForwardToNextMonthCents: 29800,
      advanceToNextMonthCents: 0,
      status: SettlementStatus.pending,
      generatedAt: now,
      updatedAt: now,
    );
    final bill = MonthlyBill(
      service: service,
      monthKey: '2026-06',
      totalQuantity: 14,
      grossAmountCents: 14000,
      advanceAmountCents: 0,
      payableAmountCents: 29800,
      lines: const [],
      advances: const [],
      settlement: settlement,
    );

    final bytes = await const PdfStatementService().buildStatement(bill);
    final source = latin1.decode(bytes, allowInvalid: true);
    final pages = RegExp(r'/Type\s*/Page(?!s)').allMatches(source).length;

    expect(bytes, isNotEmpty);
    expect(pages, 1);
  });
}
