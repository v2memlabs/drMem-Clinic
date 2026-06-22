import '../models/tenant_membership_user.dart';
import 'tenant_membership_failure.dart';

abstract interface class TenantMembershipRepository {
  Future<List<TenantMembershipUser>> listCurrentTenantMembers();

  Future<void> updateRole({
    required String membershipId,
    required String role,
  });

  Future<void> updateStatus({
    required String membershipId,
    required String status,
  });

  Future<void> updateLoginUsername({
    required String profileId,
    required String loginUsername,
  });
}

class TenantMembershipRepositoryException implements Exception {
  const TenantMembershipRepositoryException(this.failure, this.message);

  final TenantMembershipFailure failure;
  final String message;

  @override
  String toString() => message;
}
