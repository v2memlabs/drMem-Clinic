import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_physiotherapy_session_repository_contract.dart';
import 'mock_async_physiotherapy_session_repository_adapter.dart';
import 'physiotherapy_session_repository_backend_gate.dart';
import 'physiotherapy_repository.dart';
import 'supabase_async_physiotherapy_session_repository_stub.dart';
import 'supabase_physiotherapy_session_repository.dart';

/// FTR seans notu repository çözümleyici — referrals ayrı provider.
abstract final class PhysiotherapySessionRepositoryProvider {
  static AsyncPhysiotherapySessionRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncPhysiotherapySessionRepositoryContract? testOverride;

  static PhysiotherapyRepository get instance => PhysiotherapyRepository.instance;

  static AsyncPhysiotherapySessionRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteSessions => _shouldUseRemoteSessions();

  static AsyncPhysiotherapySessionRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteSessions(),
      mockFactory: () => MockAsyncPhysiotherapySessionRepositoryAdapter(),
      remoteFactory: () => SupabasePhysiotherapySessionRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncPhysiotherapySessionRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteSessions() {
    return PhysiotherapySessionRepositoryBackendGate.shouldUseRemoteSessions(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isSessionRoleEligible: AuthSession.canViewPhysiotherapy,
    );
  }

  static void resetCache() {
    _asyncCache = null;
  }

  @visibleForTesting
  static void clearTestOverrides() {
    testOverride = null;
  }
}
