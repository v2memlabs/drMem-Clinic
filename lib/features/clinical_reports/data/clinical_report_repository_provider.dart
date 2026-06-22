import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_clinical_report_repository_contract.dart';
import 'clinical_report_repository_backend_gate.dart';
import 'mock_async_clinical_report_repository_adapter.dart';
import 'supabase_async_clinical_report_repository_stub.dart';
import 'supabase_clinical_report_repository.dart';

abstract final class ClinicalReportRepositoryProvider {
  static AsyncClinicalReportRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncClinicalReportRepositoryContract? testOverride;

  static AsyncClinicalReportRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteClinicalReports => _shouldUseRemoteClinicalReports();

  static AsyncClinicalReportRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteClinicalReports(),
      mockFactory: () => MockAsyncClinicalReportRepositoryAdapter(),
      remoteFactory: () => SupabaseClinicalReportRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncClinicalReportRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteClinicalReports() {
    return ClinicalReportRepositoryBackendGate.shouldUseRemoteClinicalReports(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isClinicalReportRoleEligible:
          AuthSession.canViewClinicalReports || AuthSession.canEditClinicalReports,
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
