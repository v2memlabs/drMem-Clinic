import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_profile_settings_repository.dart';
import 'profile_settings_repository.dart';
import 'profile_settings_repository_stub.dart';
import 'supabase_profile_settings_repository.dart';

abstract final class ProfileSettingsRepositoryProvider {
  static ProfileSettingsRepository? _cache;

  @visibleForTesting
  static ProfileSettingsRepository? testOverride;

  static ProfileSettingsRepository get repository {
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

  static ProfileSettingsRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => const MockProfileSettingsRepository(),
      remoteFactory: () => SupabaseProfileSettingsRepository.fromSupabase(),
      unavailableFactory: () => const ProfileSettingsRepositoryStub(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
