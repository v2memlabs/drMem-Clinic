import '../../shared/models/app_user.dart';
import 'membership_loader.dart';
import 'session_bootstrap.dart';

/// Supabase membership placeholder — remote sorgu yok (Paket 6+).
class SupabaseMembershipLoaderStub implements MembershipLoader {
  const SupabaseMembershipLoaderStub();

  @override
  Future<SessionBootstrapResult> loadForAppUser(AppUser user) async {
    return SessionBootstrapResult.backendNotConfigured();
  }

  @override
  Future<SessionBootstrapResult> loadForProfileId(String profileId) async {
    return SessionBootstrapResult.backendNotConfigured();
  }

  @override
  Future<SessionBootstrapResult> loadForAuthUserId(String authUserId) async {
    return SessionBootstrapResult.backendNotConfigured();
  }
}
