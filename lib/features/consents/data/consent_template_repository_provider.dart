import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_consent_template_repository_contract.dart';
import 'consent_template_repository_backend_gate.dart';
import 'mock_async_consent_template_repository_adapter.dart';
import 'supabase_consent_template_repository.dart';

abstract final class ConsentTemplateRepositoryProvider {
  static AsyncConsentTemplateRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncConsentTemplateRepositoryContract? testOverride;

  static AsyncConsentTemplateRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _invalidateCacheIfStale();
    return _asyncCache ??= _resolveAsync();
  }

  static void _invalidateCacheIfStale() {
    final cached = _asyncCache;
    if (cached == null) return;

    final remoteReady = _shouldUseRemoteConsentTemplates();
    final cachedIsStub = cached is SupabaseConsentTemplateRepositoryStub;
    final cachedIsRemote = cached is SupabaseConsentTemplateRepository;

    if (remoteReady && cachedIsStub) {
      _asyncCache = null;
      return;
    }
    if (!remoteReady && cachedIsRemote) {
      _asyncCache = null;
    }
  }

  static bool get usesRemoteConsentTemplates =>
      _shouldUseRemoteConsentTemplates();

  static AsyncConsentTemplateRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteConsentTemplates(),
      mockFactory: () => MockAsyncConsentTemplateRepositoryAdapter(),
      remoteFactory: () => SupabaseConsentTemplateRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseConsentTemplateRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteConsentTemplates() {
    return ConsentTemplateRepositoryBackendGate.shouldUseRemoteConsentTemplates(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isTemplateRoleEligible:
          AuthSession.canViewConsentTemplates || AuthSession.canEditConsents,
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
