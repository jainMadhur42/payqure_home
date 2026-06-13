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
}
