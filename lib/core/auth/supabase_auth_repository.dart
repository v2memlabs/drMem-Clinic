import 'dart:async' show unawaited;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_user.dart';
import '../config/supabase_env_config.dart';
import '../data/backend_config.dart';
import '../data/repository_registry.dart';
import '../session/auth_session_bridge.dart';
import '../session/session_readiness.dart';
import 'invitation_acceptance.dart';
import 'pending_invitation_store.dart';
import 'auth_bootstrap_mapper.dart';
import 'auth_failure_reason.dart';
import 'auth_repository_contract.dart';
import '../constants/app_roles.dart';
import 'auth_session.dart';
import 'auth_session_snapshot.dart';
import 'auth_sign_in_result.dart';
import 'session_termination.dart';

/// Supabase Auth — e-posta/şifre + profile/membership bootstrap (yalnızca anon key).
class SupabaseAuthRepository implements AuthRepositoryContract {
  SupabaseClient get _client => Supabase.instance.client;

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

    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
    }

    SessionReadiness.markInitializing();

    try {
      final response = await _client.functions.invoke(
        'sign-in-with-username',
        body: {
          'username': trimmedUsername,
          'password': password,
        },
      );

      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        SessionReadiness.clear();
        return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
      }

      final sessionPayload = data['session'];
      if (sessionPayload is! Map) {
        SessionReadiness.clear();
        return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
      }

      final accessToken = sessionPayload['access_token'];
      final refreshToken = sessionPayload['refresh_token'];
      if (accessToken is! String ||
          refreshToken is! String ||
          accessToken.isEmpty ||
          refreshToken.isEmpty) {
        SessionReadiness.clear();
        return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
      }

      await _client.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );

      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        SessionReadiness.clear();
        return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
      }

      var bootstrap = await RepositoryRegistry.membershipLoader
          .loadForAuthUserId(authUser.id);

      if (!bootstrap.isReady && !bootstrap.isMaintenanceReady) {
        bootstrap = await InvitationAcceptance.tryAcceptAndReload(
          initial: bootstrap,
          loader: RepositoryRegistry.membershipLoader,
          authUserId: authUser.id,
          membershipId: PendingInvitationStore.membershipId,
        );
      }

      SessionReadiness.markBootstrapResult(bootstrap);

      if (bootstrap.isMaintenanceReady && bootstrap.context != null) {
        final bridgeResult = AuthSessionBridge.setFromMaintenanceBootstrap(
          bootstrap.context!,
        );
        if (!bridgeResult.success) {
          await _abortAuthenticatedSignIn();
          return AuthSignInResult.failure(
            AuthFailureReason.membershipUnavailable,
          );
        }
        final ctx = bootstrap.context!;
        final user = AppUser(
          id: ctx.profile.profileId,
          username: ctx.profile.preferredLoginIdentity,
          displayName: ctx.profile.displayName,
          role: AppRoles.maintenanceOperator,
        );
        return AuthSignInResult.signedIn(user: user, bootstrap: ctx);
      }

      if (!bootstrap.isReady || bootstrap.context == null) {
        await _abortAuthenticatedSignIn();
        final reason = AuthBootstrapMapper.toFailureReason(bootstrap.status);
        return AuthSignInResult.failure(reason);
      }

      final bridgeResult =
          AuthSessionBridge.setFromBootstrapContext(bootstrap.context!);
      if (!bridgeResult.success) {
        await _abortAuthenticatedSignIn();
        return AuthSignInResult.failure(AuthFailureReason.membershipUnavailable);
      }

      final ctx = bootstrap.context!;
      final user = AppUser(
        id: ctx.profile.profileId,
        username: ctx.profile.preferredLoginIdentity,
        displayName: ctx.profile.displayName,
        role: ctx.activeFlutterRole,
      );

      return AuthSignInResult.signedIn(
        user: user,
        bootstrap: ctx,
      );
    } on AuthException {
      await _abortAuthenticatedSignIn();
      return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
    } on FunctionException {
      SessionReadiness.clear();
      await _abortAuthenticatedSignIn();
      return AuthSignInResult.failure(AuthFailureReason.invalidCredentials);
    } catch (_) {
      await _abortAuthenticatedSignIn();
      return AuthSignInResult.failure(AuthFailureReason.membershipUnavailable);
    }
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
    // Profil remote güncelleme — sonraki faz.
  }

  /// Auth başarılı ama bootstrap/bridge başarısız — yerel oturum sıfırlanır.
  Future<void> _abortAuthenticatedSignIn() async {
    await SessionTermination.signOutRemoteAndLocal();
  }
}
