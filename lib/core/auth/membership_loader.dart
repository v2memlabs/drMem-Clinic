import '../../shared/models/app_user.dart';
import 'session_bootstrap.dart';

/// Profile + memberships + tenant yükleme (mock veya Supabase).
abstract interface class MembershipLoader {
  /// Mock demo: [AppUser] sonrası membership bağlamı.
  Future<SessionBootstrapResult> loadForAppUser(AppUser user);

  /// Supabase: auth sonrası profile id ile.
  Future<SessionBootstrapResult> loadForProfileId(String profileId);

  /// Supabase: [auth.users.id] ile profil + membership yükleme.
  Future<SessionBootstrapResult> loadForAuthUserId(String authUserId);
}
