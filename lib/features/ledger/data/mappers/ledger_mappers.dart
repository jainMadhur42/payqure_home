import 'package:drift/drift.dart';

import '../../domain/entities/advance_payment.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/user_profile.dart';
import '../database/ledger_database.dart';

extension ProfileMapper on ProfileRecord {
  UserProfile toDomain() {
    return UserProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      emailVerified: emailVerified,
      privacyPolicyAccepted: false,
      privacyPolicyVersion: '',
    );
  }
}

extension ServiceRecordMapper on ServiceRecord {
  HouseholdService toDomain(
    List<ServiceEntry> entries, {
    String? activeMonthKey,
  }) {
    return HouseholdService(
      id: id,
      userId: userId,
      name: name,
      description: description,
      icon: icon,
      templateType: _templateType(templateType),
      monthKey: activeMonthKey ?? monthKey,
      unit: unit,
      defaultQuantity: defaultQuantity,
      rateCents: rateCents,
      monthlyAmountCents: monthlyAmountCents,
      entries: entries,
      pendingSync: pendingSync,
      updatedAt: updatedAt,
    );
  }
}

extension EntryRecordMapper on EntryRecord {
  ServiceEntry toDomain() {
    return ServiceEntry(
      id: id,
      serviceId: serviceId,
      day: day,
      monthKey: monthKey,
      status: _entryStatus(status),
      quantity: quantity,
      unit: unit,
      rateCents: rateCents,
      amountCents: amountCents,
      note: note,
      updatedAt: updatedAt,
      pendingSync: pendingSync,
    );
  }
}

extension AdvanceRecordMapper on AdvancePaymentRecord {
  AdvancePayment toDomain() {
    return AdvancePayment(
      id: id,
      serviceId: serviceId,
      monthKey: monthKey,
      amountCents: amountCents,
      paidOn: paidOn,
      note: note,
      pendingSync: pendingSync,
    );
  }
}

extension PaymentTransactionRecordMapper on PaymentTransactionRecord {
  PaymentTransaction toDomain() {
    return PaymentTransaction(
      id: id,
      userId: userId,
      serviceId: serviceId,
      monthKey: monthKey,
      amountCents: amountCents,
      paymentDate: paymentDate,
      mode: _paymentMode(paymentMode),
      note: note,
      currentMonthAmountCents: currentMonthAmountCents,
      previousBalanceAmountCents: previousBalanceAmountCents,
      advanceAmountCents: advanceAmountCents,
      updatedAt: updatedAt,
      pendingSync: pendingSync,
      isDeleted: isDeleted,
    );
  }
}

extension MonthlySettlementRecordMapper on MonthlySettlementRecord {
  MonthlySettlement toDomain() {
    return MonthlySettlement(
      id: id,
      userId: userId,
      serviceId: serviceId,
      monthKey: monthKey,
      grossAmountCents: grossAmountCents,
      advanceUsedCents: advanceUsedCents,
      previousCarryForwardCents: previousCarryForwardCents,
      previousAdvanceCents: previousAdvanceCents,
      payableAmountCents: payableAmountCents,
      paidAmountCents: paidAmountCents,
      remainingAmountCents: remainingAmountCents,
      carryForwardToNextMonthCents: carryForwardToNextMonthCents,
      advanceToNextMonthCents: advanceToNextMonthCents,
      status: _settlementStatus(status),
      generatedAt: generatedAt,
      updatedAt: updatedAt,
      pendingSync: pendingSync,
    );
  }
}

extension ServiceEntryCompanionMapper on ServiceEntry {
  EntryRecordsCompanion toCompanion() {
    return EntryRecordsCompanion.insert(
      id: id,
      serviceId: serviceId,
      monthKey: monthKey,
      day: day,
      status: status.name,
      quantity: Value(quantity),
      unit: Value(unit),
      rateCents: Value(rateCents),
      amountCents: Value(amountCents),
      note: Value(note),
      updatedAt: updatedAt,
      pendingSync: Value(pendingSync),
    );
  }
}

extension PaymentTransactionCompanionMapper on PaymentTransaction {
  PaymentTransactionRecordsCompanion toCompanion() {
    return PaymentTransactionRecordsCompanion.insert(
      id: id,
      userId: userId,
      serviceId: serviceId,
      monthKey: monthKey,
      amountCents: amountCents,
      paymentDate: paymentDate,
      paymentMode: mode.dbValue,
      note: Value(note),
      currentMonthAmountCents: Value(currentMonthAmountCents),
      previousBalanceAmountCents: Value(previousBalanceAmountCents),
      advanceAmountCents: Value(advanceAmountCents),
      createdAt: updatedAt,
      updatedAt: updatedAt,
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }
}

extension MonthlySettlementCompanionMapper on MonthlySettlement {
  MonthlySettlementRecordsCompanion toCompanion() {
    return MonthlySettlementRecordsCompanion.insert(
      id: id,
      userId: userId,
      serviceId: serviceId,
      monthKey: monthKey,
      grossAmountCents: Value(grossAmountCents),
      advanceUsedCents: Value(advanceUsedCents),
      previousCarryForwardCents: Value(previousCarryForwardCents),
      previousAdvanceCents: Value(previousAdvanceCents),
      payableAmountCents: Value(payableAmountCents),
      paidAmountCents: Value(paidAmountCents),
      remainingAmountCents: Value(remainingAmountCents),
      carryForwardToNextMonthCents: Value(carryForwardToNextMonthCents),
      advanceToNextMonthCents: Value(advanceToNextMonthCents),
      status: status.name,
      generatedAt: generatedAt,
      updatedAt: updatedAt,
      pendingSync: Value(pendingSync),
    );
  }
}

ServiceTemplateType _templateType(String value) {
  return ServiceTemplateType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ServiceTemplateType.quantity,
  );
}

ServiceEntryStatus _entryStatus(String value) {
  return ServiceEntryStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ServiceEntryStatus.noEntry,
  );
}

PaymentMode _paymentMode(String value) {
  if (value == 'bank_transfer') {
    return PaymentMode.other;
  }
  return PaymentMode.values.firstWhere(
    (mode) => mode.name == value || mode.dbValue == value,
    orElse: () => PaymentMode.other,
  );
}

SettlementStatus _settlementStatus(String value) {
  return SettlementStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => SettlementStatus.pending,
  );
}
