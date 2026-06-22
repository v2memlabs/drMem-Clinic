import '../../../core/auth/auth_session.dart';
import '../../../core/auth/tenant_role_mapper.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/tenant_membership_user.dart';
import 'mock_tenant_membership_store.dart';
import 'tenant_membership_error_mapper.dart';
import 'tenant_membership_failure.dart';
import 'tenant_membership_repository.dart';

class MockTenantMembershipRepository implements TenantMembershipRepository {
  MockTenantMembershipRepository({List<TenantMembershipUser>? seed}) {
    if (seed != null) {
      MockTenantMembershipStore.members = List.of(seed);
    }
  }

  List<TenantMembershipUser> get _members => MockTenantMembershipStore.members;

  String? get _currentMembershipId =>
      ActiveTenantContextStore.current?.membership.id;

  void _ensureCanManage() {
    if (!AuthSession.canEditClinicProfile) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.forbidden,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.forbidden),
      );
    }
  }

  int _activeDoctorCount() =>
      _members.where((m) => m.isActiveDoctorAdmin).length;

  TenantMembershipUser? _find(String membershipId) {
    try {
      return _members.firstWhere((m) => m.membershipId == membershipId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TenantMembershipUser>> listCurrentTenantMembers() async {
    _ensureCanManage();
    return List.unmodifiable(_members);
  }

  @override
  Future<void> updateRole({
    required String membershipId,
    required String role,
  }) async {
    _ensureCanManage();
    if (!TenantRoleMapper.isKnownDbRole(role)) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.invalidRole,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.invalidRole),
      );
    }

    final index = _members.indexWhere((m) => m.membershipId == membershipId);
    if (index < 0) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.notFound,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.notFound),
      );
    }

    final target = _members[index];
    if (membershipId == _currentMembershipId) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.selfUpdateBlocked,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.selfUpdateBlocked),
      );
    }

    if (target.isActiveDoctorAdmin &&
        role != TenantRoleMapper.dbDoctorAdmin &&
        _activeDoctorCount() <= 1) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.lastAdminBlocked,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.lastAdminBlocked),
      );
    }

    _members[index] = TenantMembershipUser(
      membershipId: target.membershipId,
      profileId: target.profileId,
      displayName: target.displayName,
      email: target.email,
      loginUsername: target.loginUsername,
      role: role,
      status: target.status,
      createdAt: target.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateStatus({
    required String membershipId,
    required String status,
  }) async {
    _ensureCanManage();
    const valid = {'active', 'invited', 'disabled'};
    if (!valid.contains(status)) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.invalidStatus,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.invalidStatus),
      );
    }

    final index = _members.indexWhere((m) => m.membershipId == membershipId);
    if (index < 0) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.notFound,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.notFound),
      );
    }

    final target = _members[index];
    if (target.status == 'invited' && status == 'active') {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.invitationAcceptanceRequired,
        TenantMembershipErrorMapper.messageFor(
          TenantMembershipFailure.invitationAcceptanceRequired,
        ),
      );
    }

    if (membershipId == _currentMembershipId && status == 'disabled') {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.selfUpdateBlocked,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.selfUpdateBlocked),
      );
    }

    if (target.isActiveDoctorAdmin &&
        status == 'disabled' &&
        _activeDoctorCount() <= 1) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.lastAdminBlocked,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.lastAdminBlocked),
      );
    }

    _members[index] = TenantMembershipUser(
      membershipId: target.membershipId,
      profileId: target.profileId,
      displayName: target.displayName,
      email: target.email,
      loginUsername: target.loginUsername,
      role: target.role,
      status: status,
      createdAt: target.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateLoginUsername({
    required String profileId,
    required String loginUsername,
  }) async {
    _ensureCanManage();
    final normalized = loginUsername.trim().toLowerCase();
    final index = _members.indexWhere((m) => m.profileId == profileId);
    if (index < 0) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.notFound,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.notFound),
      );
    }
    _members[index] = TenantMembershipUser(
      membershipId: _members[index].membershipId,
      profileId: _members[index].profileId,
      displayName: _members[index].displayName,
      email: _members[index].email,
      loginUsername: normalized,
      role: _members[index].role,
      status: _members[index].status,
      createdAt: _members[index].createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
