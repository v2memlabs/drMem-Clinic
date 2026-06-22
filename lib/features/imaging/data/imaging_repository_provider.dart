import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_imaging_repository_contract.dart';
import 'imaging_repository.dart';
import 'imaging_repository_backend_gate.dart';
import 'mock_async_imaging_repository_adapter.dart';
import 'supabase_async_imaging_repository_stub.dart';
import 'supabase_imaging_repository.dart';

abstract final class ImagingRepositoryProvider {
  static AsyncImagingRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncImagingRepositoryContract? testOverride;

  static ImagingRepository get instance => ImagingRepository.instance;

  static AsyncImagingRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteImagingNotes => _shouldUseRemoteImagingNotes();

  static AsyncImagingRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteImagingNotes(),
      mockFactory: () => MockAsyncImagingRepositoryAdapter(),
      remoteFactory: () => SupabaseImagingRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncImagingRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteImagingNotes() {
    return ImagingRepositoryBackendGate.shouldUseRemoteImagingNotes(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isImagingRoleEligible:
          AuthSession.canViewImaging || AuthSession.canEditImaging,
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
