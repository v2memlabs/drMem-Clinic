/// Uygulama kullanıcı profili (auth kullanıcısından ayrı metadata).
class UserProfile {
  final String userId;
  final String displayName;

  const UserProfile({
    required this.userId,
    required this.displayName,
  });
}
