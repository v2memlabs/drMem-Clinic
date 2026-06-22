import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v2a-1 migration defines tenant create RPC and guards', () {
    final file = File(
      'supabase/migrations/20260804100000_maintenance_bootstrap_console_v2a1_tenant_create.sql',
    );
    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('maintenance_create_tenant_v2'));
    expect(sql, contains('maintenance_assert_operator()'));
    expect(sql, contains('insert into public.tenants'));
    expect(sql, contains('clinic_workflow_settings'));
    expect(sql, contains('on conflict (tenant_id) do nothing'));
    expect(sql, contains('maintenance.tenant.create'));
    expect(sql, contains('maintenance_v2a1'));
    expect(sql, contains('empty_tenant_name'));
    expect(sql, contains('invalid_tenant_status'));

    expect(sql, isNot(contains('maintenance_bootstrap_user_v2')));
    expect(sql, isNot(contains('maintenance_bootstrap_status_v2')));
    expect(sql, isNot(contains('insert into auth.users')));
    expect(sql, isNot(contains("'password'")));
  });

  test('v2a-1 audit metadata avoids forbidden keys in SQL literals', () {
    final sql = File(
      'supabase/migrations/20260804100000_maintenance_bootstrap_console_v2a1_tenant_create.sql',
    ).readAsStringSync();

    expect(sql.toLowerCase(), isNot(contains("'email'")));
    expect(sql.toLowerCase(), isNot(contains("'display_name'")));
    expect(sql.toLowerCase(), isNot(contains("'jwt'")));
    expect(sql.toLowerCase(), isNot(contains("'service_role'")));
  });
}
