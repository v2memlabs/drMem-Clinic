import 'pending_invitation_store.dart';
import '../../features/settings/data/tenant_invite_failure.dart';
import '../../features/settings/data/tenant_invite_repository_provider.dart';
import 'auth_failure_reason.dart';
import 'membership_loader.dart';
import 'session_bootstrap.dart';
/// Davetli kullanıcı login bootstrap — inactiveMembership sonrası accept denemesi.
abstract final class InvitationAcceptance {
  static Future<SessionBootstrapResult> tryAcceptAndReload({
    required SessionBootstrapResult initial,
    required MembershipLoader loader,
    required String authUserId,
    String? membershipId,
  }) async {
    if (initial.isReady || initial.context != null) {
      return initial;
    }

    if (initial.status != SessionBootstrapStatus.inactiveMembership) {
      return initial;
    }

    final targetMembershipId =
        membershipId ?? PendingInvitationStore.membershipId;

    try {
      await TenantInviteRepositoryProvider.repository.acceptMyInvitation(
        membershipId: targetMembershipId,
      );
      PendingInvitationStore.clear();
    } on TenantInviteRepositoryException catch (e) {
      return _mapAcceptFailure(e.failure);
    } catch (_) {
      return SessionBootstrapResult.invitationAcceptFailed();
    }

    return loader.loadForAuthUserId(authUserId);
  }

  static SessionBootstrapResult _mapAcceptFailure(TenantInviteFailure failure) {
    switch (failure) {
      case TenantInviteFailure.multiplePendingInvitations:
        return SessionBootstrapResult.multiplePendingInvitations();
      case TenantInviteFailure.invitationNotFound:
        return SessionBootstrapResult.inactiveMembership();
      default:
        return SessionBootstrapResult.invitationAcceptFailed();
    }
  }

  static AuthFailureReason mapBootstrapToAuthFailure(SessionBootstrapStatus status) {
    switch (status) {
      case SessionBootstrapStatus.invitationAcceptFailed:
        return AuthFailureReason.invitationAcceptFailed;
      case SessionBootstrapStatus.multiplePendingInvitations:
        return AuthFailureReason.multiplePendingInvitations;
      default:
        return AuthFailureReason.membershipUnavailable;
    }
  }
}
