import 'tenant_invite_error_mapper.dart';
import 'tenant_invite_failure.dart';
import 'tenant_invite_models.dart';
import 'tenant_invite_repository.dart';

class TenantInviteRepositoryStub implements TenantInviteRepository {
  const TenantInviteRepositoryStub();

  Never _notConfigured() => throw TenantInviteRepositoryException(
        TenantInviteFailure.notConfigured,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.notConfigured),
      );

  @override
  Future<TenantInviteResult> inviteUser(TenantInviteRequest request) async =>
      _notConfigured();

  @override
  Future<TenantInviteResult> resendInvitation(String membershipId) async =>
      _notConfigured();

  @override
  Future<InvitationCancelResult> cancelInvitation(String membershipId) async =>
      _notConfigured();

  @override
  Future<InvitationAcceptResult> acceptMyInvitation({
    String? membershipId,
  }) async =>
      _notConfigured();
}
