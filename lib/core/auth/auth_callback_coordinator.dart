import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client_initializer.dart';
import '../data/backend_config.dart';
import 'auth_password_paths.dart';
import 'auth_password_setup_intent.dart';
import 'auth_session.dart';
import 'invitation_deep_link.dart';
import 'pending_invitation_store.dart';
import 'session_local_cleanup.dart';
import 'startup_session_purge.dart';

/// Supabase Auth deep-link olaylarını uygulama rotalarına yönlendirir.
abstract final class AuthCallbackCoordinator {
  static StreamSubscription<AuthState>? _subscription;

  static void start(GoRouter router) {
    if (!AppBackendConfig.isSupabase || !SupabaseClientInitializer.isInitialized) {
      return;
    }

    _captureInitialInvitationLink();
    _subscription?.cancel();
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) => _handleAuthState(router, data),
    );
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  @visibleForTesting
  static void handleAuthStateForTest(GoRouter router, AuthState data) {
    _handleAuthState(router, data);
  }

  static void _captureInitialInvitationLink() {
    if (!kIsWeb) return;
    final membershipId = InvitationDeepLink.parseMembershipId(Uri.base.toString());
    if (membershipId != null) {
      PendingInvitationStore.setMembershipId(membershipId);
    }
  }

  static void _handleAuthState(GoRouter router, AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.initialSession:
        // Cold start: persist edilmiş oturum restore edilmez (StartupSessionPurge).
        return;
      case AuthChangeEvent.tokenRefreshed:
        return;
      case AuthChangeEvent.signedOut:
        SessionLocalCleanup.clearAll(clearPendingInvitation: false);
        return;
      case AuthChangeEvent.passwordRecovery:
        AuthPasswordSetupIntent.markRequired();
        router.go(AuthPasswordPaths.updatePasswordPath);
        return;
      case AuthChangeEvent.signedIn:
        if (!StartupSessionPurge.isCompleted) return;
        if (data.session == null || AuthSession.isLoggedIn) return;
        if (PendingInvitationStore.membershipId != null) {
          AuthPasswordSetupIntent.markRequired();
          router.go(AuthPasswordPaths.updatePasswordPath);
        }
        return;
      default:
        return;
    }
  }
}
