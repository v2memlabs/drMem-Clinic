import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/settings/data/mock_staff_leave_request_repository.dart';
import 'package:v2mem_clinic/features/settings/data/staff_leave_request_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/staff_leave_record.dart';
import 'package:v2mem_clinic/features/settings/models/staff_leave_request.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    StaffLeaveRequestRepositoryProvider.resetCache();
    StaffLeaveRequestRepositoryProvider.testOverride = null;
    ActiveTenantContextStore.clearSilently();
    AuthSession.clear();
  });

  test('mock repository creates pending leave request', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-1',
        username: 'asistan',
        displayName: 'Asistan A',
        role: AppRoles.assistant,
      ),
    );
    ActiveTenantContextStore.set(
      const ActiveTenantContext(
        tenant: Tenant(id: 'tenant-1', name: 'Test Klinik', specialty: ''),
        membership: Membership(
          id: 'm1',
          tenantId: 'tenant-1',
          userId: 'profile-1',
          role: AppRoles.assistant,
          status: 'active',
        ),
        profile: UserProfile(userId: 'profile-1', displayName: 'Asistan A'),
      ),
    );

    StaffLeaveRequestRepositoryProvider.testOverride =
        MockStaffLeaveRequestRepository();

    final now = DateTime.now();
    final created = await StaffLeaveRequestRepositoryProvider.repository.create(
      StaffLeaveRequestDraft(
        leaveType: StaffLeaveType.annual,
        startsAt: DateTime(now.year, now.month, now.day, 9),
        endsAt: DateTime(now.year, now.month, now.day, 18),
        note: 'Tatil',
      ),
    );

    expect(created.status, StaffLeaveRequestStatus.pending);
    expect(created.staffDisplayName, 'Asistan A');

    final mine = await StaffLeaveRequestRepositoryProvider.repository.listMine();
    expect(mine, hasLength(1));
  });
}
