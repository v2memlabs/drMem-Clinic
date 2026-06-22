import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260601100000_auth_context_helper_hotfix_v1.sql',
  );

  test('auth context helper hotfix migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration defines profile lookup via auth_user_id', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create or replace function public.current_profile_id()'));
    expect(sql, contains('p.auth_user_id = auth.uid()'));
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
  });

  test('migration defines tenant lookup via active membership', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create or replace function public.current_tenant_id()'));
    expect(sql, contains('m.profile_id = public.current_profile_id()'));
    expect(sql, contains("m.status = 'active'"));
    expect(sql, isNot(contains("auth.jwt() ->> 'profile_id'")));
    expect(sql, isNot(contains("auth.jwt() ->> 'tenant_id'")));
  });
}
