import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'package:flutter/foundation.dart';

import 'clinic_workflow_settings_repository.dart';
import 'mock_clinic_workflow_settings_repository.dart';
import 'clinic_workflow_settings_repository_stub.dart';
import 'supabase_clinic_workflow_settings_repository.dart';

abstract final class ClinicWorkflowSettingsRepositoryProvider {
  static ClinicWorkflowSettingsRepository? _cache;

  @visibleForTesting
  static ClinicWorkflowSettingsRepository? testOverride;

  static ClinicWorkflowSettingsRepository get repository {
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

  static ClinicWorkflowSettingsRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => MockClinicWorkflowSettingsRepository(),
      remoteFactory: () => SupabaseClinicWorkflowSettingsRepository.fromSupabase(),
      unavailableFactory: () => const ClinicWorkflowSettingsRepositoryStub(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
