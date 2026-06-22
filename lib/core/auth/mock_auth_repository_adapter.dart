import 'dart:async' show unawaited;

import '../../shared/models/app_user.dart';
import 'session_termination.dart';
import 'auth_failure_reason.dart';
import 'auth_repository_contract.dart';
import 'auth_session.dart';
import 'auth_session_snapshot.dart';
import 'auth_sign_in_result.dart';
import 'tenant_role_mapper.dart';

/// Mevcut [AuthSession] ve [mockLogin] davranışını sözleşmeye bağlar.
///
/// Aktif login ekranı hâlâ doğrudan [mockLogin] kullanır; bu adapter
/// [RepositoryRegistry.auth] ve sonraki paketler için hazırdır.
class MockAuthRepositoryAdapter implements AuthRepositoryContract {
  @override
  bool get isLoggedIn => AuthSession.isLoggedIn;

  @override
  AuthSessionSnapshot get currentSession =>
      AuthSessionSnapshot.fromUser(AuthSession.currentUser);

  @override
  Future<AuthSignInResult> signInMock({
    required String username,
    required String password,
    required String role,
  }) async {
    if (!TenantRoleMapper.isKnownFlutterRole(role)) {
      return AuthSignInResult.failure(AuthFailureReason.unknownRole);
    }

    final user = await mockLogin(username, password, role);
    if (user == null) {
      return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
    }

    return AuthSignInResult.signedIn(user: user);
  }

  @override
  Future<AuthSignInResult> signInWithUsername({
    required String username,
    required String password,
  }) async {
    return AuthSignInResult.failure(AuthFailureReason.emailSignInNotSupported);
  }

  @override
  void signOut() {
    unawaited(signOutAsync());
  }

  @override
  Future<void> signOutAsync() async {
    await SessionTermination.signOutRemoteAndLocal();
  }

  @override
  void updateDisplayName(String displayName) {
    AuthSession.updateDisplayName(displayName);
  }
}
