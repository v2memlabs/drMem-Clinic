import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_radiology_order_repository_contract.dart';
import 'mock_async_radiology_order_repository_adapter.dart';
import 'radiology_order_repository_backend_gate.dart';
import 'supabase_async_radiology_order_repository_stub.dart';
import 'supabase_radiology_order_repository.dart';

abstract final class RadiologyOrderRepositoryProvider {
  static AsyncRadiologyOrderRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncRadiologyOrderRepositoryContract? testOverride;

  static AsyncRadiologyOrderRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteRadiologyOrders => _shouldUseRemoteRadiologyOrders();

  static AsyncRadiologyOrderRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteRadiologyOrders(),
      mockFactory: () => MockAsyncRadiologyOrderRepositoryAdapter(),
      remoteFactory: () => SupabaseRadiologyOrderRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncRadiologyOrderRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteRadiologyOrders() {
    return RadiologyOrderRepositoryBackendGate.shouldUseRemoteRadiologyOrders(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isRadiologyOrderRoleEligible:
          AuthSession.canViewRadiologyOrders || AuthSession.canEditRadiologyOrders,
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
