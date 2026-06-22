import 'tenant_invite_models.dart';

abstract interface class TenantInviteRepository {
  Future<TenantInviteResult> inviteUser(TenantInviteRequest request);

  Future<TenantInviteResult> resendInvitation(String membershipId);

  Future<InvitationCancelResult> cancelInvitation(String membershipId);

  Future<InvitationAcceptResult> acceptMyInvitation({String? membershipId});
}
