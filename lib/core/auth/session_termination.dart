import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client_initializer.dart';
import '../data/backend_config.dart';
import 'session_local_cleanup.dart';

/// Supabase sign-out + yerel oturum temizliği (explicit logout ve lifecycle).
abstract final class SessionTermination {
  static Future<void> signOutRemoteAndLocal({
    bool clearPendingInvitation = true,
  }) async {
    await _signOutSupabaseBestEffort();
    SessionLocalCleanup.clearAll(clearPendingInvitation: clearPendingInvitation);
  }

  static Future<void> _signOutSupabaseBestEffort() async {
    if (!AppBackendConfig.isSupabase || !SupabaseClientInitializer.isInitialized) {
      return;
    }
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
    }
  }
}
