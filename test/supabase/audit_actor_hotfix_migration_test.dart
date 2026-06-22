import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final legacy = File(
    'supabase/migrations/20260525100000_audit_access_event_extension_v1.sql',
  );
  final pack = File(
    'supabase/migrations/20260805110000_p0_stabilization_integrity_pack_v1.sql',
  );
  final maintenance = File(
    'supabase/migrations/20260602100000_maintenance_bootstrap_console_v1.sql',
  );

  test('legacy audit RPC used wrong profiles.user_id column', () {
    final sql = legacy.readAsStringSync();
    expect(sql, contains('p.user_id = auth.uid()'));
    expect(sql, isNot(contains('p.auth_user_id = auth.uid()')));
  });

  test('P0 hotfix uses auth_user_id with tenant membership scope', () {
    final sql = pack.readAsStringSync();
    final auditSection = sql.split('record_audit_access_event')[1];
    expect(auditSection, contains('p.auth_user_id = auth.uid()'));
    expect(auditSection, contains('m.tenant_id = v_tenant_id'));
    expect(auditSection, isNot(contains('p.user_id = auth.uid()')));
  });

  test('maintenance audit already resolves operator via auth_user_id', () {
    final sql = maintenance.readAsStringSync();
    expect(sql, contains('maintenance_assert_operator'));
    expect(sql, contains('p.auth_user_id = auth.uid()'));
    expect(sql, contains('actor_profile_id'));
  });
}
