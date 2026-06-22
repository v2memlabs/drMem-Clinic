import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_tenant_invite_repository.dart';
import 'supabase_tenant_invite_repository.dart';
import 'tenant_invite_repository_stub.dart';
import 'tenant_invite_repository.dart';

abstract final class TenantInviteRepositoryProvider {
  static TenantInviteRepository? _cache;

  @visibleForTesting
  static TenantInviteRepository? testOverride;

  static TenantInviteRepository get repository {
    if (testOverride != null) return testOverride!;
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get _supabaseReady =>
      AppBackendConfig.isSupabase &&
      SupabaseEnvConfig.isSupabaseConfigured &&
      SupabaseClientInitializer.isInitialized;

  static bool get _hasSupabaseAuthSession {
    if (!_supabaseReady) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// Invite form: oturum hazır + aktif tenant. Accept login sırasında da Supabase RPC gerekir.
  static bool get usesRemote =>
      _supabaseReady &&
      _hasSupabaseAuthSession &&
      (SessionReadiness.isReady
          ? ActiveTenantContextStore.current != null
          : true);

  static TenantInviteRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => MockTenantInviteRepository(),
      remoteFactory: () => SupabaseTenantInviteRepository.fromSupabase(),
      unavailableFactory: () => const TenantInviteRepositoryStub(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
