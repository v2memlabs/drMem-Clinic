import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_audit_log_repository_contract.dart';
import 'audit_log_repository.dart';
import 'audit_log_repository_backend_gate.dart';
import 'mock_async_audit_log_repository_adapter.dart';
import 'supabase_async_audit_log_repository_stub.dart';
import 'supabase_audit_log_repository.dart';

abstract final class AuditLogRepositoryProvider {
  static AsyncAuditLogRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncAuditLogRepositoryContract? testOverride;

  /// Sync mock — lookup fallback / mock adapter delegasyonu.
  static AuditLogRepository get instance => AuditLogRepository.instance;

  static AsyncAuditLogRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteAuditLogs => _shouldUseRemoteAuditLogs();

  static AsyncAuditLogRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteAuditLogs(),
      mockFactory: () => MockAsyncAuditLogRepositoryAdapter(),
      remoteFactory: () => SupabaseAuditLogRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncAuditLogRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteAuditLogs() {
    return AuditLogRepositoryBackendGate.shouldUseRemoteAuditLogs(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isAuditRoleEligible: AuthSession.canViewAuditLogs,
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
