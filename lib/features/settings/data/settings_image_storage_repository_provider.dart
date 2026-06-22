import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_settings_image_storage_repository.dart';
import 'settings_image_storage_repository.dart';
import 'settings_image_storage_repository_stub.dart';
import 'supabase_settings_image_storage_repository.dart';

abstract final class SettingsImageStorageRepositoryProvider {
  static SettingsImageStorageRepository? _cache;

  @visibleForTesting
  static SettingsImageStorageRepository? testOverride;

  static SettingsImageStorageRepository get repository {
    if (testOverride != null) return testOverride!;
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get usesRemoteStorage => _shouldUseRemoteStorage();

  static SettingsImageStorageRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteStorage(),
      mockFactory: () => MockSettingsImageStorageRepository(),
      remoteFactory: () => SupabaseSettingsImageStorageRepository.fromSupabase(),
      unavailableFactory: () => const SettingsImageStorageRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteStorage() {
    if (AppBackendConfig.isMock) return false;
    if (!SupabaseEnvConfig.isSupabaseConfigured) return false;
    if (!SupabaseClientInitializer.isInitialized) return false;
    if (!AuthSession.isLoggedIn) return false;
    if (!SessionReadiness.isReady) return false;
    if (ActiveTenantContextStore.current == null) return false;
    return true;
  }

  static void resetCache() {
    _cache = null;
  }
}
