import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260607100000_settings_user_invitation_v2a.sql',
  );

  test('settings user invitation v2a migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration defines bootstrap and accept RPCs', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('bootstrap_tenant_invited_user_v2'));
    expect(sql, contains('accept_my_tenant_invitation_v2'));
    expect(sql, contains('_user_mgmt_assert_doctor_admin()'));
    expect(sql, contains("status = 'invited'"));
    expect(sql, contains('invitation.accepted'));
    expect(sql, contains('user.invite.send'));
    expect(sql, contains('settings_invitation_v2a'));
  });

  test('migration blocks manual invited to active status update', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('invitation_acceptance_required'));
    expect(
      sql,
      contains("v_before_status = 'invited' and p_status = 'active'"),
    );
  });

  test('canonical guard restored in P0 hotfix after membership v1 regression', () {
    final hotfix = File(
      'supabase/migrations/20260805110000_p0_stabilization_integrity_pack_v1.sql',
    );
    expect(hotfix.existsSync(), isTrue);
    final sql = hotfix.readAsStringSync();
    expect(sql, contains('update_tenant_membership_status_v1'));
    expect(sql, contains('invitation_acceptance_required'));
    expect(sql, contains('invitation_flow_required'));
  });

  test('bootstrap RPC does not return sensitive fields in contract comments', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains("'email', p.email")));
    expect(sql, isNot(contains("'auth_user_id', p_auth_user_id")));
    expect(sql, contains('target_profile_id'));
    expect(sql, contains('target_membership_id'));
  });

  test('accept RPC handles multiple pending invitations', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('multiple_pending_invitations'));
  });
}
