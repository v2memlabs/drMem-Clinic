import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_membership_user.dart';

void main() {
  test('parseListResponse maps RPC rows', () {
    final members = TenantMembershipUser.parseListResponse([
      {
        'membership_id': '11111111-1111-1111-1111-111111111111',
        'display_name': 'Dr. Test',
        'email': 'd@test.local',
        'role': 'doctor_admin',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      },
    ]);

    expect(members.length, 1);
    expect(members.first.displayName, 'Dr. Test');
    expect(members.first.email, 'd@test.local');
    expect(members.first.role, 'doctor_admin');
    expect(members.first.status, 'active');
    expect(members.first.membershipId, isNotEmpty);
  });

  test('parseListResponse ignores non-list payloads', () {
    expect(TenantMembershipUser.parseListResponse(null), isEmpty);
    expect(TenantMembershipUser.parseListResponse({'ok': true}), isEmpty);
  });
}
