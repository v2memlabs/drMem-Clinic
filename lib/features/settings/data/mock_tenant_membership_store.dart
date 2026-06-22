import '../../../core/auth/tenant_role_mapper.dart';
import '../../../core/session/mock_profile_ids.dart';
import '../models/tenant_membership_user.dart';

/// Mock backend — paylaşılan üyelik listesi (invite + list parity).
abstract final class MockTenantMembershipStore {
  static List<TenantMembershipUser> members = List.of(_defaultSeed);

  static List<TenantMembershipUser> get _defaultSeed => [
        const TenantMembershipUser(
          membershipId: 'mem-doctor',
          profileId: MockProfileIds.primaryDoctor,
          displayName: 'Dr. Mehmet Yalçınozan',
          email: 'doktor@ornek.klinik',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
        const TenantMembershipUser(
          membershipId: 'mem-assistant',
          displayName: 'Ayşe Asistan',
          email: 'asistan@ornek.klinik',
          role: TenantRoleMapper.dbAssistantSecretary,
          status: 'active',
        ),
      ];

  static void reset() {
    members = List.of(_defaultSeed);
    lastInvitedAtByMembership.clear();
  }

  static String nextMembershipId() => 'mem-invite-${members.length + 1}';

  static final Map<String, DateTime> lastInvitedAtByMembership = {};

  static void markInvited(String membershipId) {
    lastInvitedAtByMembership[membershipId] = DateTime.now();
  }
}
