import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_clinical_encounter_repository_contract.dart';
import 'clinical_encounter_repository.dart';
import 'clinical_encounter_repository_backend_gate.dart';
import 'mock_async_clinical_encounter_repository_adapter.dart';
import 'supabase_async_clinical_encounter_repository_stub.dart';
import 'supabase_clinical_encounter_repository.dart';

/// Muayene repository çözümleyici — sync UI mock; async remote hazır.
///
/// Full-table remote yalnızca doctor_admin (`AuthSession.canViewFullClinicalEncounter`).
/// Asistan/FTR/hemşire mock async adapter alır; safe summary ayrı faz.
abstract final class ClinicalEncounterRepositoryProvider {
  static AsyncClinicalEncounterRepositoryContract? _asyncCache;
  static bool? _cachedRemoteReady;

  /// Test override — async repository enjeksiyonu.
  static AsyncClinicalEncounterRepositoryContract? testOverride;

  /// Mevcut sync singleton — UI ekranları hâlâ bunu kullanır (mock in-memory).
  static ClinicalEncounterRepository get instance =>
      ClinicalEncounterRepository.instance;

  /// Async muayene repository — smoke/ileride UI; backend + oturum + rol koşullu.
  static AsyncClinicalEncounterRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    final remoteReady = _shouldUseRemoteClinicalEncounters();
    if (_asyncCache == null || _cachedRemoteReady != remoteReady) {
      _cachedRemoteReady = remoteReady;
      _asyncCache = _resolveAsync();
    }
    return _asyncCache!;
  }

  /// Aktif async implementasyon Supabase full-table mi?
  static bool get usesRemoteClinicalEncounters =>
      _shouldUseRemoteClinicalEncounters();

  static AsyncClinicalEncounterRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteClinicalEncounters(),
      mockFactory: () => MockAsyncClinicalEncounterRepositoryAdapter(),
      remoteFactory: () => SupabaseClinicalEncounterRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncClinicalEncounterRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteClinicalEncounters() {
    return ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isDoctorFullTableEligible:
          AuthSession.canViewFullClinicalEncounter ||
          AuthSession.canEditClinicalEncounters,
    );
  }

  /// Test veya oturum değişiminde cache sıfırlama.
  static void resetCache() {
    _asyncCache = null;
    _cachedRemoteReady = null;
  }

  static void clearTestOverrides() {
    testOverride = null;
  }
}
