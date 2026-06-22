import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_patient_tag_repository.dart';
import 'patient_tag_repository_contract.dart';
import 'patient_tag_repository_stub.dart';
import 'supabase_patient_tag_repository.dart';

abstract final class PatientTagRepositoryProvider {
  static PatientTagRepositoryContract? _cache;

  @visibleForTesting
  static PatientTagRepositoryContract? testOverride;

  static PatientTagRepositoryContract get repository {
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

  static PatientTagRepositoryContract _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => const MockPatientTagRepository(),
      remoteFactory: () => SupabasePatientTagRepository.fromSupabase(),
      unavailableFactory: () => const PatientTagRepositoryStub(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
