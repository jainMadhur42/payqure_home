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
}
