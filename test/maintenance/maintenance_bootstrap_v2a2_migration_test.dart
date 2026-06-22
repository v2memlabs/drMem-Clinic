import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v2a-2 migration defines bootstrap RPCs and guards', () {
    final file = File(
      'supabase/migrations/20260804200000_maintenance_bootstrap_console_v2a2_admin_bootstrap.sql',
    );
    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('maintenance_bootstrap_user_v2'));
    expect(sql, contains('maintenance_bootstrap_status_v2'));
    expect(sql, contains('maintenance_assert_operator()'));
    expect(sql, contains('maintenance.bootstrap.complete'));
    expect(sql, contains('maintenance_v2a2'));
    expect(sql, contains('profile_conflict'));
    expect(sql, contains('auth_user_already_linked'));
    expect(sql, contains('membership_exists'));
    expect(sql, contains('maintenance_operator_target_rejected'));
    expect(sql, contains('gap_code'));

    expect(sql, isNot(contains('maintenance_create_tenant_v2')));
    expect(sql, isNot(contains("'password'")));
    expect(sql, isNot(contains('insert into auth.users')));
  });

  test('v2a-2 audit metadata avoids forbidden keys in SQL literals', () {
    final sql = File(
      'supabase/migrations/20260804200000_maintenance_bootstrap_console_v2a2_admin_bootstrap.sql',
    ).readAsStringSync();

    expect(sql.toLowerCase(), isNot(contains("'email'")));
    expect(sql.toLowerCase(), isNot(contains("'display_name'")));
    expect(sql.toLowerCase(), isNot(contains("'jwt'")));
    expect(sql.toLowerCase(), isNot(contains("'service_role'")));
  });
}
