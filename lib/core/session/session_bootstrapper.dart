import '../../shared/models/app_user.dart';
import '../auth/membership_loader.dart';
import '../auth/membership_resolver.dart';
import '../auth/session_bootstrap.dart';
import 'active_tenant_context_loader.dart';
import 'auth_session_bridge.dart';
import 'session_bridge_result.dart';
import 'session_context_resolver.dart';

/// Login sonrası membership yükleme → bootstrap → bridge (aktif login mock bridge kullanır).
///
/// Hedef: `RepositoryRegistry.auth` → [MembershipResolver] → [applyBootstrapContext].
abstract final class SessionBootstrapper {
  static MembershipLoader get membershipLoader => MembershipResolver.loader;

  static ActiveTenantContextLoader get tenantLoader =>
      SessionContextResolver.tenantLoader;

  /// Mock [AppUser] için membership + active tenant bağlamı üretir (login UI bağlı değil).
  static Future<SessionBootstrapResult> bootstrapFromMockUser(AppUser user) {
    return membershipLoader.loadForAppUser(user);
  }

  /// Profile id ile yükleme (Supabase stub → [backendNotConfigured]).
  static Future<SessionBootstrapResult> bootstrapFromProfileId(String profileId) {
    return membershipLoader.loadForProfileId(profileId);
  }

  /// Bootstrap bağlamını oturuma uygular.
  static SessionBridgeResult applyBootstrapContext(SessionBootstrapContext context) {
    return AuthSessionBridge.setFromBootstrapContext(context);
  }

  /// Bootstrap sonucu hazırsa oturuma uygular.
  static SessionBridgeResult applyBootstrapResult(SessionBootstrapResult result) {
    if (!result.isReady || result.context == null) {
      return SessionBridgeResult.failure(SessionBridgeFailure.bootstrapNotReady);
    }
    if (result.isMaintenanceReady) {
      return AuthSessionBridge.setFromMaintenanceBootstrap(result.context!);
    }
    return applyBootstrapContext(result.context!);
  }
}
