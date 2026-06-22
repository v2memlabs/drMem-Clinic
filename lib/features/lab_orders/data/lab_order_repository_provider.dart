import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_lab_order_repository_contract.dart';
import 'lab_order_repository_backend_gate.dart';
import 'mock_async_lab_order_repository_adapter.dart';
import 'supabase_async_lab_order_repository_stub.dart';
import 'supabase_lab_order_repository.dart';

abstract final class LabOrderRepositoryProvider {
  static AsyncLabOrderRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncLabOrderRepositoryContract? testOverride;

  static AsyncLabOrderRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteLabOrders => _shouldUseRemoteLabOrders();

  static AsyncLabOrderRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteLabOrders(),
      mockFactory: () => MockAsyncLabOrderRepositoryAdapter(),
      remoteFactory: () => SupabaseLabOrderRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncLabOrderRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteLabOrders() {
    return LabOrderRepositoryBackendGate.shouldUseRemoteLabOrders(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isLabOrderRoleEligible:
          AuthSession.canViewLabOrders || AuthSession.canEditLabOrders,
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
