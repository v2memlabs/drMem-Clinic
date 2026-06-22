import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_prescription_repository_contract.dart';
import 'mock_async_prescription_repository_adapter.dart';
import 'prescription_repository_backend_gate.dart';
import 'supabase_async_prescription_repository_stub.dart';
import 'supabase_prescription_repository.dart';

abstract final class PrescriptionRepositoryProvider {
  static AsyncPrescriptionRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncPrescriptionRepositoryContract? testOverride;

  static AsyncPrescriptionRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemotePrescriptions => _shouldUseRemotePrescriptions();

  static AsyncPrescriptionRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePrescriptions(),
      mockFactory: () => MockAsyncPrescriptionRepositoryAdapter(),
      remoteFactory: () => SupabasePrescriptionRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncPrescriptionRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePrescriptions() {
    return PrescriptionRepositoryBackendGate.shouldUseRemotePrescriptions(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPrescriptionRoleEligible:
          AuthSession.canViewPrescriptions || AuthSession.canEditPrescriptions,
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
