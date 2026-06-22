import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'mock_async_physiotherapy_referral_repository_adapter.dart';
import 'physiotherapy_referral_repository_backend_gate.dart';
import 'physiotherapy_repository.dart';
import 'supabase_async_physiotherapy_referral_repository_stub.dart';
import 'supabase_physiotherapy_referral_repository.dart';

/// FTR yönlendirme repository çözümleyici — sessions mock sync kalır.
abstract final class PhysiotherapyReferralRepositoryProvider {
  static AsyncPhysiotherapyReferralRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncPhysiotherapyReferralRepositoryContract? testOverride;

  static PhysiotherapyRepository get instance => PhysiotherapyRepository.instance;

  static AsyncPhysiotherapyReferralRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _invalidateCacheIfStale();
    return _asyncCache ??= _resolveAsync();
  }

  static void _invalidateCacheIfStale() {
    final cached = _asyncCache;
    if (cached == null) return;

    final remoteReady = _shouldUseRemoteReferrals();
    final cachedIsStub = cached is SupabaseAsyncPhysiotherapyReferralRepositoryStub;
    final cachedIsRemote = cached is SupabasePhysiotherapyReferralRepository;

    if (remoteReady && cachedIsStub) {
      _asyncCache = null;
      return;
    }
    if (!remoteReady && cachedIsRemote) {
      _asyncCache = null;
    }
  }

  static bool get usesRemoteReferrals => _shouldUseRemoteReferrals();

  static AsyncPhysiotherapyReferralRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteReferrals(),
      mockFactory: () => MockAsyncPhysiotherapyReferralRepositoryAdapter(),
      remoteFactory: () => SupabasePhysiotherapyReferralRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncPhysiotherapyReferralRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteReferrals() {
    return PhysiotherapyReferralRepositoryBackendGate.shouldUseRemoteReferrals(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isReferralRoleEligible: AuthSession.canViewPhysiotherapy ||
          AuthSession.canEditPhysiotherapy ||
          AuthSession.canEditClinicalEncounters,
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
