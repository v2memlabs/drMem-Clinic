import '../../../core/auth/auth_session.dart';
import '../../../core/auth/tenant_role_mapper.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/tenant_membership_user.dart';
import 'mock_tenant_membership_store.dart';
import 'tenant_invite_error_mapper.dart';
import 'tenant_invite_failure.dart';
import 'tenant_invite_models.dart';
import 'tenant_invite_repository.dart';

class MockTenantInviteRepository implements TenantInviteRepository {
  void _ensureCanInvite() {
    if (!AuthSession.canEditClinicProfile) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.forbidden,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.forbidden),
      );
    }
  }

  TenantMembershipUser? _findMember(String membershipId) {
    try {
      return MockTenantMembershipStore.members
          .firstWhere((m) => m.membershipId == membershipId);
    } catch (_) {
      return null;
    }
  }

  void _assertResendAllowed(String membershipId) {
    final last = MockTenantMembershipStore.lastInvitedAtByMembership[membershipId];
    if (last != null && DateTime.now().difference(last).inSeconds < 60) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.inviteRateLimited,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.inviteRateLimited),
      );
    }
  }

  @override
  Future<TenantInviteResult> inviteUser(TenantInviteRequest request) async {
    _ensureCanInvite();

    final email = request.email.trim();
    final displayName = request.displayName.trim();
    if (email.isEmpty || !email.contains('@')) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invalidEmail,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invalidEmail),
      );
    }
    if (displayName.isEmpty) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invalidDisplayName,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invalidDisplayName),
      );
    }
    if (!TenantRoleMapper.isKnownDbRole(request.role)) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invalidRole,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invalidRole),
      );
    }

    final normalizedEmail = email.toLowerCase();
    final existingIndex = MockTenantMembershipStore.members.indexWhere(
      (m) => (m.email ?? '').toLowerCase() == normalizedEmail,
    );

    if (existingIndex >= 0) {
      final existing = MockTenantMembershipStore.members[existingIndex];
      if (existing.status == 'active') {
        throw TenantInviteRepositoryException(
          TenantInviteFailure.membershipAlreadyActive,
          TenantInviteErrorMapper.messageFor(
            TenantInviteFailure.membershipAlreadyActive,
          ),
        );
      }
      if (existing.status == 'invited' && existing.role == request.role) {
        MockTenantMembershipStore.markInvited(existing.membershipId);
        return TenantInviteResult(
          operationResult: 'invitation_already_pending',
          targetMembershipId: existing.membershipId,
          role: existing.role,
          status: 'invited',
        );
      }

      MockTenantMembershipStore.members[existingIndex] = TenantMembershipUser(
        membershipId: existing.membershipId,
        displayName: displayName,
        email: email,
        role: request.role,
        status: 'invited',
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      MockTenantMembershipStore.markInvited(existing.membershipId);

      return TenantInviteResult(
        operationResult: existing.status == 'disabled' ? 'reinvited' : 'created',
        targetMembershipId: existing.membershipId,
        role: request.role,
        status: 'invited',
      );
    }

    final membershipId = MockTenantMembershipStore.nextMembershipId();
    MockTenantMembershipStore.members.add(
      TenantMembershipUser(
        membershipId: membershipId,
        displayName: displayName,
        email: email,
        role: request.role,
        status: 'invited',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    MockTenantMembershipStore.markInvited(membershipId);

    return TenantInviteResult(
      operationResult: 'created',
      targetMembershipId: membershipId,
      role: request.role,
      status: 'invited',
    );
  }

  @override
  Future<TenantInviteResult> resendInvitation(String membershipId) async {
    _ensureCanInvite();

    final member = _findMember(membershipId);
    if (member == null) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationNotFound,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotFound),
      );
    }
    if (member.status != 'invited') {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationNotPending,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotPending),
      );
    }

    _assertResendAllowed(membershipId);
    MockTenantMembershipStore.markInvited(membershipId);

    return TenantInviteResult(
      operationResult: 'resent',
      targetMembershipId: membershipId,
      role: member.role,
      status: 'invited',
    );
  }

  @override
  Future<InvitationCancelResult> cancelInvitation(String membershipId) async {
    _ensureCanInvite();

    final index = MockTenantMembershipStore.members
        .indexWhere((m) => m.membershipId == membershipId);
    if (index < 0) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationNotFound,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotFound),
      );
    }

    final member = MockTenantMembershipStore.members[index];
    if (member.status != 'invited') {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationNotPending,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotPending),
      );
    }

    MockTenantMembershipStore.members[index] = TenantMembershipUser(
      membershipId: member.membershipId,
      displayName: member.displayName,
      email: member.email,
      role: member.role,
      status: 'disabled',
      createdAt: member.createdAt,
      updatedAt: DateTime.now(),
    );

    return InvitationCancelResult(
      membershipId: membershipId,
      status: 'disabled',
    );
  }

  @override
  Future<InvitationAcceptResult> acceptMyInvitation({
    String? membershipId,
  }) async {
    final profileId = ActiveTenantContextStore.current?.profile.userId;
    if (profileId == null) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationNotFound,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotFound),
      );
    }

    final invited = MockTenantMembershipStore.members
        .where((m) => m.status == 'invited')
        .toList();

    if (invited.isEmpty) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationNotFound,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotFound),
      );
    }

    TenantMembershipUser target;
    if (membershipId != null && membershipId.isNotEmpty) {
      try {
        target = invited.firstWhere((m) => m.membershipId == membershipId);
      } catch (_) {
        throw TenantInviteRepositoryException(
          TenantInviteFailure.invitationNotFound,
          TenantInviteErrorMapper.messageFor(TenantInviteFailure.invitationNotFound),
        );
      }
    } else {
      if (invited.length > 1) {
        throw TenantInviteRepositoryException(
          TenantInviteFailure.multiplePendingInvitations,
          TenantInviteErrorMapper.messageFor(
            TenantInviteFailure.multiplePendingInvitations,
          ),
        );
      }
      target = invited.first;
    }
    final index = MockTenantMembershipStore.members.indexWhere(
      (m) => m.membershipId == target.membershipId,
    );
    MockTenantMembershipStore.members[index] = TenantMembershipUser(
      membershipId: target.membershipId,
      displayName: target.displayName,
      email: target.email,
      role: target.role,
      status: 'active',
      createdAt: target.createdAt,
      updatedAt: DateTime.now(),
    );

    return InvitationAcceptResult(
      membershipId: target.membershipId,
      tenantId: ActiveTenantContextStore.current?.tenant.id ?? 'tenant-demo',
      role: target.role,
      status: 'active',
    );
  }
}
