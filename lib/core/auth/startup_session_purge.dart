import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client_initializer.dart';
import '../data/backend_config.dart';
import 'invitation_deep_link.dart';
import 'pending_invitation_store.dart';
import 'session_local_cleanup.dart';
import 'session_termination.dart';
import 'supabase_auth_url_session.dart';

enum StartupSessionPurgeOutcome {
  notApplicable,
  purgedPersistedSession,
  authCallbackRecovered,
}

/// Cold-start güvenlik politikası: persist edilmiş oturum restore edilmez.
abstract final class StartupSessionPurge {
  static bool _completed = false;

  static bool get isCompleted => _completed;

  @visibleForTesting
  static void resetForTest() {
    _completed = false;
  }

  static void _capturePendingInvitationFromUrl() {
    if (!kIsWeb) return;
    final membershipId =
        InvitationDeepLink.parseMembershipId(Uri.base.toString());
    if (membershipId != null) {
      PendingInvitationStore.setMembershipId(membershipId);
    }
  }

  /// Supabase init sonrası, router render öncesi çağrılır.
  static Future<StartupSessionPurgeOutcome> run() async {
    _capturePendingInvitationFromUrl();
    SessionLocalCleanup.clearAll(clearPendingInvitation: false);

    if (!AppBackendConfig.isSupabase || !SupabaseClientInitializer.isInitialized) {
      _completed = true;
      return StartupSessionPurgeOutcome.notApplicable;
    }

    final uri = kIsWeb ? Uri.base : Uri();
    if (SupabaseAuthUrlSession.hasAuthCallbackInUri(uri)) {
      await SupabaseAuthUrlSession.recoverFromUri(uri);
      SessionLocalCleanup.clearAll(clearPendingInvitation: false);
      _completed = true;
      return StartupSessionPurgeOutcome.authCallbackRecovered;
    }

    if (Supabase.instance.client.auth.currentSession != null) {
      await SessionTermination.signOutRemoteAndLocal(clearPendingInvitation: false);
      _completed = true;
      return StartupSessionPurgeOutcome.purgedPersistedSession;
    }

    _completed = true;
    return StartupSessionPurgeOutcome.notApplicable;
  }
}
