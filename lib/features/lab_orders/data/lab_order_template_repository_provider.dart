import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_lab_order_template_repository_contract.dart';
import 'lab_order_template_repository_backend_gate.dart';
import 'mock_async_lab_order_template_repository_adapter.dart';
import 'supabase_async_lab_order_template_repository_stub.dart';
import 'supabase_lab_order_template_repository.dart';

abstract final class LabOrderTemplateRepositoryProvider {
  static AsyncLabOrderTemplateRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncLabOrderTemplateRepositoryContract? testOverride;

  static AsyncLabOrderTemplateRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteLabOrderTemplates =>
      _shouldUseRemoteLabOrderTemplates();

  static AsyncLabOrderTemplateRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteLabOrderTemplates(),
      mockFactory: () => MockAsyncLabOrderTemplateRepositoryAdapter(),
      remoteFactory: () => SupabaseLabOrderTemplateRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncLabOrderTemplateRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteLabOrderTemplates() {
    return LabOrderTemplateRepositoryBackendGate.shouldUseRemoteLabOrderTemplates(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isLabOrderTemplateRoleEligible:
          AuthSession.canViewLabOrders ||
          AuthSession.canManageLabOrderTemplates,
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
