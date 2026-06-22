import 'auth_session_snapshot.dart';
import 'auth_sign_in_result.dart';

/// Auth oturum sözleşmesi — mock demo ve Supabase (ileride) yolları ayrıdır.
///
/// - **Mock:** [signInMock] — rol login dropdown'dan gelir.
/// - **Supabase:** [signInWithEmail] — rol membership'ten gelir; role parametresi yok.
abstract interface class AuthRepositoryContract {
  bool get isLoggedIn;

  /// Pasif oturum özeti (UI/router geçişinde kullanılabilir).
  AuthSessionSnapshot get currentSession;

  /// Mock: demo kullanıcı adı/şifre + seçilen rol.
  Future<AuthSignInResult> signInMock({
    required String username,
    required String password,
    required String role,
  });

  /// Supabase: kullanıcı adı → e-posta çözümleme → şifre ile giriş.
  Future<AuthSignInResult> signInWithUsername({
    required String username,
    required String password,
  });

  void signOut();

  Future<void> signOutAsync();

  void updateDisplayName(String displayName);
}
