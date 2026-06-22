import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user membership management migration defines required RPCs and guards', () {
    final file = File(
      'supabase/migrations/20260803100000_user_membership_management_v1.sql',
    );
    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('list_tenant_memberships_v1'));
    expect(sql, contains('update_tenant_membership_role_v1'));
    expect(sql, contains('update_tenant_membership_status_v1'));
    expect(sql, contains('_user_mgmt_assert_doctor_admin'));
    expect(sql, contains('has_tenant_role'));
    expect(sql, contains('current_tenant_id()'));
    expect(sql, contains('self_update_blocked'));
    expect(sql, contains('last_admin_blocked'));
    expect(sql, isNot(contains('invitation_acceptance_required')));

    final hotfix = File(
      'supabase/migrations/20260805110000_p0_stabilization_integrity_pack_v1.sql',
    );
    expect(hotfix.existsSync(), isTrue);
    final hotfixSql = hotfix.readAsStringSync();
    expect(hotfixSql, contains('invitation_acceptance_required'));
    expect(hotfixSql, contains('invitation_flow_required'));
    expect(sql, contains('maintenance_operator'));
    expect(sql, contains('membership.role_update'));
    expect(sql, contains('membership.status_update'));
    expect(sql, contains('user_management'));
    expect(sql, contains('settings_v1'));

    expect(sql, isNot(contains('maintenance_list_memberships')));
    expect(sql, isNot(contains('maintenance_update_membership_role')));
    expect(sql, contains("'membership_id', m.id"));
  });
}
