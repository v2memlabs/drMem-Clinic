/// Davet deep-link membership_id — login/accept arası geçici taşıyıcı.
abstract final class PendingInvitationStore {
  static String? _membershipId;

  static String? get membershipId => _membershipId;

  static void setMembershipId(String? membershipId) {
    _membershipId = membershipId;
  }

  static void clear() {
    _membershipId = null;
  }

  static void clearSilently() => clear();
}
