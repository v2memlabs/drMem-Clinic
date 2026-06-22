/// Settings invitation v2d — davet kabul deep-link parse (yalnız membership_id).
abstract final class InvitationDeepLink {
  static const acceptPath = '/invite/accept';
  static const membershipIdParam = 'membership_id';

  static final RegExp _uuid =
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);

  static bool isAcceptPath(String location) {
    final path = Uri.tryParse(location)?.path;
    return path == acceptPath;
  }

  static String? parseMembershipId(String? location) {
    if (location == null || location.isEmpty) return null;
    final uri = Uri.tryParse(location);
    if (uri == null) return null;
    if (uri.path != acceptPath) return null;
    return normalizeMembershipId(uri.queryParameters[membershipIdParam]);
  }

  static String? normalizeMembershipId(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (!_uuid.hasMatch(value)) return null;
    return value.toLowerCase();
  }

  static String buildAcceptLocation(String membershipId) {
    final id = normalizeMembershipId(membershipId);
    if (id == null) return acceptPath;
    return '$acceptPath?$membershipIdParam=$id';
  }
}
