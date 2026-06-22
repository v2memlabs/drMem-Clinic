import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_consent_repository_contract.dart';
import 'consent_repository.dart';
import 'consent_repository_backend_gate.dart';
import 'mock_async_consent_repository_adapter.dart';
import 'supabase_consent_repository.dart';
import 'supabase_consent_repository_stub.dart';

abstract final class ConsentRepositoryProvider {
  static AsyncConsentRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncConsentRepositoryContract? testOverride;

  static ConsentRepository get instance => ConsentRepository.instance;

  static AsyncConsentRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _invalidateCacheIfStale();
    return _asyncCache ??= _resolveAsync();
  }

  /// Oturum/rol hazır olmadan stub cache'lendiyse remote'a geç.
  static void _invalidateCacheIfStale() {
    final cached = _asyncCache;
    if (cached == null) return;

    final remoteReady = _shouldUseRemoteConsents();
    final cachedIsStub = cached is SupabaseConsentRepositoryStub;
    final cachedIsRemote = cached is SupabaseConsentRepository;

    if (remoteReady && cachedIsStub) {
      _asyncCache = null;
      return;
    }
    if (!remoteReady && cachedIsRemote) {
      _asyncCache = null;
    }
  }

  static bool get usesRemoteConsents => _shouldUseRemoteConsents();

  static AsyncConsentRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteConsents(),
      mockFactory: () => MockAsyncConsentRepositoryAdapter(),
      remoteFactory: () => SupabaseConsentRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseConsentRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteConsents() {
    return ConsentRepositoryBackendGate.shouldUseRemoteConsents(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isConsentRoleEligible:
          AuthSession.canViewConsents || AuthSession.canEditConsents,
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
