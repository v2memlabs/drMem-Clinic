import '../../shared/models/app_user.dart';
import 'auth_failure_reason.dart';
import 'session_bootstrap.dart';

/// Tek giriş denemesinin sonucu (mock veya Supabase yolu).
class AuthSignInResult {
  final bool success;
  final AppUser? user;
  final SessionBootstrapContext? bootstrap;
  final AuthFailureReason? failure;

  const AuthSignInResult._({
    required this.success,
    this.user,
    this.bootstrap,
    this.failure,
  });

  factory AuthSignInResult.signedIn({
    required AppUser user,
    SessionBootstrapContext? bootstrap,
  }) {
    return AuthSignInResult._(
      success: true,
      user: user,
      bootstrap: bootstrap,
    );
  }

  factory AuthSignInResult.failure(AuthFailureReason reason) {
    return AuthSignInResult._(
      success: false,
      failure: reason,
    );
  }

  bool get hasBootstrap => bootstrap != null;
}
