import '../config/supabase_env_config.dart';
import '../data/backend_config.dart';
import 'auth_failure_reason.dart';
import 'auth_repository_contract.dart';
import 'auth_session_snapshot.dart';
import 'auth_sign_in_result.dart';

/// Supabase Auth placeholder — gerçek client init yok (Paket 6).
class SupabaseAuthRepositoryStub implements AuthRepositoryContract {
  @override
  bool get isLoggedIn => false;

  @override
  AuthSessionSnapshot get currentSession => AuthSessionSnapshot.empty();

  @override
  Future<AuthSignInResult> signInMock({
    required String username,
    required String password,
    required String role,
  }) async {
    return AuthSignInResult.failure(AuthFailureReason.mockSignInNotSupported);
  }

  @override
  Future<AuthSignInResult> signInWithUsername({
    required String username,
    required String password,
  }) async {
    if (!SupabaseEnvConfig.isSupabaseConfigured || !AppBackendConfig.isSupabase) {
      return AuthSignInResult.failure(AuthFailureReason.backendNotConfigured);
    }
    return AuthSignInResult.failure(AuthFailureReason.backendNotConfigured);
  }

  @override
  void signOut() {}

  @override
  Future<void> signOutAsync() async {}

  @override
  void updateDisplayName(String displayName) {}
}
