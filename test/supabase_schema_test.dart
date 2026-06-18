import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production schema persists registration phone metadata', () {
    final sql = File(
      'supabase/migrations/'
      '202606130001_create_payqure_home_production_schema.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('create or replace function public.handle_new_auth_user()'),
    );
    expect(sql, contains("metadata ->> 'phone'"));
    expect(sql, contains('after insert on auth.users'));
    expect(sql, contains('insert into public.profiles'));
  });

  test('OTP request limit resets automatically after 60 minutes', () {
    final sql = File(
      'supabase/migrations/'
      '202606130001_create_payqure_home_production_schema.sql',
    ).readAsStringSync();

    expect(sql, contains("now() - interval '60 minutes'"));
    expect(sql, contains('set request_count = 0,'));
    expect(sql, contains('blocked = false,'));
    expect(sql, contains('if current_record.request_count >= 3 then'));
  });

  test('OTP request status exposes count and hourly reset time', () {
    final migration = File(
      'supabase/migrations/202606150003_add_otp_request_window_status.sql',
    ).readAsStringSync();

    expect(migration, contains('window_started_at'));
    expect(migration, contains('window_resets_at timestamptz'));
    expect(migration, contains('request_count >= 3'));
    expect(migration, contains("interval '60 minutes'"));
    expect(
      migration,
      contains(
        'drop function if exists '
        'public.claim_auth_otp_request(text, text)',
      ),
    );
    expect(
      migration,
      contains(
        'create or replace function public.claim_auth_otp_request(\n'
        '  request_identifier text,\n'
        '  request_purpose text',
      ),
    );
  });

  test('profile schema persists the preferred currency', () {
    final migration = File(
      'supabase/migrations/202606150004_add_profile_preferred_currency.sql',
    ).readAsStringSync();

    expect(migration, contains('preferred_currency'));
    expect(migration, contains("default 'USD'"));
    expect(migration, contains("'^[A-Z]{3}\$'"));
    expect(migration, contains("values ('ledger', 8)"));
  });

  test('new schema remains compatible with older schema 6 clients', () {
    final compatibilityMigration = File(
      'supabase/migrations/202606150002_add_app_compatibility_config.sql',
    ).readAsStringSync();
    final otpMigration = File(
      'supabase/migrations/202606150003_add_otp_request_window_status.sql',
    ).readAsStringSync();
    final currencyMigration = File(
      'supabase/migrations/202606150004_add_profile_preferred_currency.sql',
    ).readAsStringSync();

    expect(
      compatibilityMigration,
      contains("values ('mobile', 3, '1.2.0', '1.6.0')"),
    );
    expect(otpMigration, contains('public.claim_auth_otp_request(text, text)'));
    expect(
      currencyMigration,
      contains("preferred_currency text not null default 'USD'"),
    );
  });

  test('compatibility config uses one schema-version source of truth', () {
    final sql = File(
      'supabase/migrations/'
      '202606150002_add_app_compatibility_config.sql',
    ).readAsStringSync();
    final createTable = sql.substring(
      sql.indexOf('create table if not exists public.app_compatibility_config'),
      sql.indexOf(');') + 2,
    );

    expect(createTable, isNot(contains('current_schema_version')));
    expect(
      sql,
      contains("'current_schema_version', public.ledger_schema_version()"),
    );
    expect(
      sql,
      contains('drop column if exists current_schema_version cascade'),
    );
  });
}
