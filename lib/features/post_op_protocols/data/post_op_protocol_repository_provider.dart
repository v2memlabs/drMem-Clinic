import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_post_op_protocol_repository_contract.dart';
import 'mock_async_post_op_protocol_repository_adapter.dart';
import 'post_op_protocol_repository.dart';
import 'post_op_protocol_repository_backend_gate.dart';
import 'supabase_async_post_op_protocol_repository_stub.dart';
import 'supabase_post_op_protocol_repository.dart';

abstract final class PostOpProtocolRepositoryProvider {
  static AsyncPostOpProtocolRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncPostOpProtocolRepositoryContract? testOverride;

  static PostOpProtocolRepository get instance =>
      PostOpProtocolRepository.instance;

  static AsyncPostOpProtocolRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemotePostOpProtocols =>
      _shouldUseRemotePostOpProtocols();

  static AsyncPostOpProtocolRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePostOpProtocols(),
      mockFactory: () => MockAsyncPostOpProtocolRepositoryAdapter(),
      remoteFactory: () => SupabasePostOpProtocolRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncPostOpProtocolRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePostOpProtocols() {
    return PostOpProtocolRepositoryBackendGate.shouldUseRemotePostOpProtocols(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPostOpProtocolRoleEligible: AuthSession.canViewPostOpProtocols ||
          AuthSession.canEditPostOpProtocols,
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
