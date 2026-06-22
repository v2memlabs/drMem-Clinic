import '../models/tenant_membership_user.dart';
import 'tenant_membership_error_mapper.dart';
import 'tenant_membership_failure.dart';
import 'tenant_membership_repository.dart';

class TenantMembershipRepositoryStub implements TenantMembershipRepository {
  const TenantMembershipRepositoryStub();

  Never _notConfigured() => throw TenantMembershipRepositoryException(
        TenantMembershipFailure.notConfigured,
        TenantMembershipErrorMapper.messageFor(
          TenantMembershipFailure.notConfigured,
        ),
      );

  @override
  Future<void> updateRole({
    required String membershipId,
    required String role,
  }) async =>
      _notConfigured();

  @override
  Future<void> updateStatus({
    required String membershipId,
    required String status,
  }) async =>
      _notConfigured();

  @override
  Future<List<TenantMembershipUser>> listCurrentTenantMembers() async =>
      _notConfigured();

  @override
  Future<void> updateLoginUsername({
    required String profileId,
    required String loginUsername,
  }) async =>
      _notConfigured();
}
