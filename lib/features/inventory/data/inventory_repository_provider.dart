import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_inventory_repository_contract.dart';
import 'inventory_repository.dart';
import 'inventory_repository_backend_gate.dart';
import 'mock_async_inventory_repository_adapter.dart';
import 'supabase_inventory_repository.dart';
import 'supabase_inventory_repository_stub.dart';

abstract final class InventoryRepositoryProvider {
  static AsyncInventoryRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncInventoryRepositoryContract? testOverride;

  static InventoryRepository get instance => InventoryRepository.instance;

  static AsyncInventoryRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteInventory => _shouldUseRemoteInventory();

  static AsyncInventoryRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteInventory(),
      mockFactory: () => MockAsyncInventoryRepositoryAdapter(),
      remoteFactory: () => SupabaseInventoryRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseInventoryRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteInventory() {
    return InventoryRepositoryBackendGate.shouldUseRemoteInventory(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isInventoryRoleEligible:
          AuthSession.canViewInventory || AuthSession.canEditInventory,
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
