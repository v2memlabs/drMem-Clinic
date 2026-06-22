import '../data/repository_cache_coordinator.dart';
import '../session/active_tenant_context_store.dart';
import '../session/session_auto_lock_controller.dart';
import '../session/session_readiness.dart';
import 'auth_session.dart';
import 'pending_invitation_store.dart';
import '../../features/settings/data/settings_persistence_sync.dart';

/// Oturum kapatma / cold-start purge için merkezi yerel temizlik.
abstract final class SessionLocalCleanup {
  static void clearAll({bool clearPendingInvitation = true}) {
    sessionAutoLockController.disarm();
    RepositoryCacheCoordinator.onSessionCleared();
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    SessionReadiness.clear();
    SettingsPersistenceSync.clearSessionScoped();
    if (clearPendingInvitation) {
      PendingInvitationStore.clear();
    }
  }
}
