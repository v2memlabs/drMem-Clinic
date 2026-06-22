import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_patient_repository_contract.dart';
import 'mock_async_patient_repository_adapter.dart';
import 'mock_patient_repository_adapter.dart';
import 'patient_repository.dart';
import 'patient_repository_backend_gate.dart';
import 'patient_repository_contract.dart';
import 'supabase_async_patient_repository_stub.dart';
import 'supabase_patient_repository.dart';

/// Hasta repository çözümleyici — sync UI mock; async remote hazır.
abstract final class PatientRepositoryProvider {
  static AsyncPatientRepositoryContract? _asyncCache;

  /// Sync contract — mock adapter (lookup fallback; production UI async/lookup).
  static PatientRepositoryContract get current => resolve();

  /// Mevcut singleton — mock in-memory (lookup fallback).
  static PatientRepository get instance => PatientRepository.instance;

  /// Async hasta repository — smoke/ileride UI; backend + oturum koşullu.
  static AsyncPatientRepositoryContract get asyncRepository {
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  /// Aktif async implementasyon Supabase mi?
  static bool get usesRemotePatients => _shouldUseRemotePatients();

  /// Sync resolver — UI kırılmaması için daima mock adapter.
  static PatientRepositoryContract resolve() {
    return MockPatientRepositoryAdapter();
  }

  static AsyncPatientRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePatients(),
      mockFactory: () => MockAsyncPatientRepositoryAdapter(),
      remoteFactory: () => SupabasePatientRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncPatientRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePatients() {
    return PatientRepositoryBackendGate.shouldUseRemotePatients(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
    );
  }

  /// Test veya oturum değişiminde cache sıfırlama.
  static void resetCache() {
    _asyncCache = null;
  }
}
