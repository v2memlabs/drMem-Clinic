import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_tenant_membership_repository.dart';
import 'supabase_tenant_membership_repository.dart';
import 'tenant_membership_repository.dart';
import 'tenant_membership_repository_stub.dart';

abstract final class TenantMembershipRepositoryProvider {
  static TenantMembershipRepository? _cache;

  @visibleForTesting
  static TenantMembershipRepository? testOverride;

  static TenantMembershipRepository get repository {
    if (testOverride != null) return testOverride!;
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get usesRemote =>
      AppBackendConfig.isSupabase &&
      SupabaseEnvConfig.isSupabaseConfigured &&
      SupabaseClientInitializer.isInitialized &&
      AuthSession.isLoggedIn &&
      SessionReadiness.isReady &&
      ActiveTenantContextStore.current != null;

  static TenantMembershipRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => MockTenantMembershipRepository(),
      remoteFactory: () => SupabaseTenantMembershipRepository.fromSupabase(),
      unavailableFactory: () => const TenantMembershipRepositoryStub(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
