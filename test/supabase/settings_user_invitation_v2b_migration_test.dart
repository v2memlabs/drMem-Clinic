import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260608100000_settings_user_invitation_v2b.sql',
  );

  test('settings user invitation v2b migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration adds last_invited_at and resend/cancel RPCs', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('last_invited_at'));
    expect(sql, contains('prepare_tenant_invitation_resend_v2'));
    expect(sql, contains('complete_tenant_invitation_resend_v2'));
    expect(sql, contains('cancel_tenant_invitation_v2'));
    expect(sql, contains('_user_mgmt_assert_doctor_admin()'));
  });

  test('resend RPC enforces invited-only and 60s cooldown', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("v_status is distinct from 'invited'"));
    expect(sql, contains('invite_rate_limited'));
    expect(sql, contains("interval '60 seconds'"));
  });

  test('cancel RPC soft-disables invited membership without delete', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("set status = 'disabled'"));
    expect(sql, isNot(contains('delete from public.memberships')));
    expect(sql, isNot(contains('delete from public.profiles')));
    expect(sql, isNot(contains('auth.admin.deleteUser')));
  });

  test('audit actions use v2b allowlist metadata', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('user.invite.resend'));
    expect(sql, contains('user.invite.cancel'));
    expect(sql, contains('settings_invitation_v2b'));
    expect(sql, contains('target_profile_id'));
    expect(sql, contains('target_membership_id'));
    expect(sql, contains('operation_result'));

    final resendAudit = sql.split("'user.invite.resend'")[1].split(');')[0];
    final cancelAudit = sql.split("'user.invite.cancel'")[1].split(');')[0];
    expect(resendAudit, isNot(contains("'email'")));
    expect(cancelAudit, isNot(contains("'email'")));
    expect(resendAudit, isNot(contains('invite_url')));
  });

  test('cancel RPC return contract excludes sensitive fields', () {
    final sql = migration.readAsStringSync();
    final cancelSection = sql.split(
      'create or replace function public.cancel_tenant_invitation_v2',
    )[1].split('grant execute on function public.cancel_tenant_invitation_v2')[0];
    expect(cancelSection, contains("'membership_id', p_membership_id"));
    expect(cancelSection, contains("'status', 'disabled'"));
    expect(cancelSection, isNot(contains("'email'")));
    expect(cancelSection, isNot(contains('token')));
  });
}
