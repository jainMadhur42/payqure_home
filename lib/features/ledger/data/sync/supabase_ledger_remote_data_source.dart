import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/ledger_month.dart';
import '../database/ledger_database.dart';

abstract interface class LedgerRemoteDataSource {
  bool get isConfigured;
  Future<int?> fetchSchemaVersion();
  Future<List<Map<String, dynamic>>> fetchServices({
    required String userId,
    required String monthKey,
  });
  Future<List<Map<String, dynamic>>> fetchMonthLogs({required String monthKey});
  Future<List<Map<String, dynamic>>> fetchAdvances({required String monthKey});
  Future<List<Map<String, dynamic>>> fetchPayments({required String monthKey});
  Future<List<Map<String, dynamic>>> fetchSettlements({
    required String monthKey,
  });
  Future<void> pushService(ServiceRecord row);
  Future<void> pushMonthLog(ServiceMonthLogRecord row);
  Future<void> pushAdvance(AdvancePaymentRecord row);
  Future<void> pushPayment(PaymentTransactionRecord row);
  Future<void> deletePayment(String id);
  Future<void> pushSettlement(MonthlySettlementRecord row);
  Future<void> pushServices(List<ServiceRecord> rows);
  Future<void> pushMonthLogs(List<ServiceMonthLogRecord> rows);
  Future<void> pushAdvances(List<AdvancePaymentRecord> rows);
  Future<void> pushPayments(List<PaymentTransactionRecord> rows);
  Future<void> pushSettlements(List<MonthlySettlementRecord> rows);
}

class SupabaseLedgerRemoteDataSource implements LedgerRemoteDataSource {
  const SupabaseLedgerRemoteDataSource(this._client);

  final SupabaseClient? _client;

  @override
  bool get isConfigured => _client != null;

  @override
  Future<int?> fetchSchemaVersion() async {
    final client = _client;
    if (client == null) {
      return null;
    }
    return client.rpc<int>('ledger_schema_version');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchServices({
    required String userId,
    required String monthKey,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }
    final rows = await client.from('services').select().eq('user_id', userId);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthLogs({
    required String monthKey,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }
    final rows = await client
        .from('service_month_logs')
        .select()
        .eq('month_key', monthKey);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdvances({
    required String monthKey,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }
    final rows = await client
        .from('advance_payments')
        .select()
        .eq('month_key', monthKey);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayments({
    required String monthKey,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }
    final rows = await client.from('payment_transactions').select().inFilter(
      'month_key',
      [monthKey, _nextMonthKey(monthKey)],
    );
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSettlements({
    required String monthKey,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }
    final rows = await client
        .from('monthly_settlements')
        .select()
        .eq('month_key', monthKey);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> pushService(ServiceRecord row) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.from('services').upsert(_serviceMap(row));
  }

  @override
  Future<void> pushServices(List<ServiceRecord> rows) async {
    final client = _client;
    if (client == null || rows.isEmpty) {
      return;
    }
    await client.from('services').upsert(rows.map(_serviceMap).toList());
  }

  @override
  Future<void> pushMonthLog(ServiceMonthLogRecord row) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.from('service_month_logs').upsert(_monthLogMap(row));
  }

  @override
  Future<void> pushMonthLogs(List<ServiceMonthLogRecord> rows) async {
    final client = _client;
    if (client == null || rows.isEmpty) {
      return;
    }
    await client
        .from('service_month_logs')
        .upsert(rows.map(_monthLogMap).toList());
  }

  @override
  Future<void> pushAdvance(AdvancePaymentRecord row) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.from('advance_payments').upsert(_advanceMap(row));
  }

  @override
  Future<void> pushAdvances(List<AdvancePaymentRecord> rows) async {
    final client = _client;
    if (client == null || rows.isEmpty) {
      return;
    }
    await client
        .from('advance_payments')
        .upsert(rows.map(_advanceMap).toList());
  }

  @override
  Future<void> pushPayment(PaymentTransactionRecord row) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.from('payment_transactions').upsert(_paymentMap(row));
  }

  @override
  Future<void> pushPayments(List<PaymentTransactionRecord> rows) async {
    final client = _client;
    if (client == null || rows.isEmpty) {
      return;
    }
    await client
        .from('payment_transactions')
        .upsert(rows.map(_paymentMap).toList());
  }

  @override
  Future<void> deletePayment(String id) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.from('payment_transactions').delete().eq('id', id);
  }

  @override
  Future<void> pushSettlement(MonthlySettlementRecord row) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.from('monthly_settlements').upsert(_settlementMap(row));
  }

  @override
  Future<void> pushSettlements(List<MonthlySettlementRecord> rows) async {
    final client = _client;
    if (client == null || rows.isEmpty) {
      return;
    }
    await client
        .from('monthly_settlements')
        .upsert(rows.map(_settlementMap).toList());
  }

  Map<String, dynamic> _serviceMap(ServiceRecord row) => {
    'id': row.id,
    'user_id': row.userId,
    'month_key': row.monthKey,
    'name': row.name,
    'description': row.description,
    'icon': row.icon,
    'template_type': row.templateType,
    'unit': row.unit,
    'default_quantity': row.defaultQuantity,
    'rate_cents': row.rateCents,
    'monthly_amount_cents': row.monthlyAmountCents,
    'updated_at': row.updatedAt.toIso8601String(),
    'is_deleted': row.isDeleted,
  };

  Map<String, dynamic> _monthLogMap(ServiceMonthLogRecord row) => {
    'id': row.id,
    'service_id': row.serviceId,
    'month_key': row.monthKey,
    'schema_version': row.schemaVersion,
    'entries_json': row.entriesJson,
    'updated_at': row.updatedAt.toIso8601String(),
    'is_deleted': row.isDeleted,
  };

  Map<String, dynamic> _advanceMap(AdvancePaymentRecord row) => {
    'id': row.id,
    'service_id': row.serviceId,
    'month_key': row.monthKey,
    'amount_cents': row.amountCents,
    'paid_on': row.paidOn.toIso8601String(),
    'note': row.note,
    'updated_at': row.updatedAt.toIso8601String(),
    'is_deleted': row.isDeleted,
  };

  Map<String, dynamic> _paymentMap(PaymentTransactionRecord row) => {
    'id': row.id,
    'user_id': row.userId,
    'service_id': row.serviceId,
    'month_key': row.monthKey,
    'amount_cents': row.amountCents,
    'payment_date': row.paymentDate.toIso8601String(),
    'payment_mode': row.paymentMode,
    'note': row.note,
    'current_month_amount_cents': row.currentMonthAmountCents,
    'previous_balance_amount_cents': row.previousBalanceAmountCents,
    'advance_amount_cents': row.advanceAmountCents,
    'created_at': row.createdAt.toIso8601String(),
    'updated_at': row.updatedAt.toIso8601String(),
    'is_deleted': row.isDeleted,
  };

  Map<String, dynamic> _settlementMap(MonthlySettlementRecord row) => {
    'id': row.id,
    'user_id': row.userId,
    'service_id': row.serviceId,
    'month_key': row.monthKey,
    'gross_amount_cents': row.grossAmountCents,
    'advance_used_cents': row.advanceUsedCents,
    'previous_carry_forward_cents': row.previousCarryForwardCents,
    'previous_advance_cents': row.previousAdvanceCents,
    'payable_amount_cents': row.payableAmountCents,
    'paid_amount_cents': row.paidAmountCents,
    'remaining_amount_cents': row.remainingAmountCents,
    'carry_forward_to_next_month_cents': row.carryForwardToNextMonthCents,
    'advance_to_next_month_cents': row.advanceToNextMonthCents,
    'status': row.status,
    'generated_at': row.generatedAt.toIso8601String(),
    'updated_at': row.updatedAt.toIso8601String(),
    'is_deleted': row.isDeleted,
  };

  String _nextMonthKey(String monthKey) {
    return LedgerMonth.parse(monthKey).shift(1).key;
  }
}
