import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_timeline_repository.dart';
import 'timeline_repository.dart';
import 'timeline_repository_backend_gate.dart';
import 'timeline_repository_stub.dart';
import 'supabase_timeline_repository.dart';

/// Hasta timeline repository çözümleyici — yalnızca timeline RPC.
abstract final class TimelineRepositoryProvider {
  static TimelineRepository? _cache;

  static TimelineRepository get repository {
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get usesRemotePatientTimeline => _shouldUseRemotePatientTimeline();

  static TimelineRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePatientTimeline(),
      mockFactory: () => MockTimelineRepository(),
      remoteFactory: () => SupabaseTimelineRepository.fromSupabase(),
      unavailableFactory: () => const TimelineRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePatientTimeline() {
    return TimelineRepositoryBackendGate.canUsePatientTimelineRemote(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isTimelineRoleEligible: AuthSession.canViewPatientTimeline,
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
