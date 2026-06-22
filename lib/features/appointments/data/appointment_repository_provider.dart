import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'appointment_repository.dart';
import 'appointment_repository_backend_gate.dart';
import 'appointment_repository_contract.dart';
import 'async_appointment_repository_contract.dart';
import 'mock_appointment_repository_adapter.dart';
import 'mock_async_appointment_repository_adapter.dart';
import 'supabase_async_appointment_repository_stub.dart';
import 'supabase_appointment_repository.dart';

/// Randevu repository çözümleyici — sync UI mock; async remote hazır.
abstract final class AppointmentRepositoryProvider {
  static AsyncAppointmentRepositoryContract? _asyncCache;

  /// Test override — async repository enjeksiyonu.
  static AsyncAppointmentRepositoryContract? testOverride;

  /// Sync contract — mock adapter (lookup fallback; production UI async/lookup).
  static AppointmentRepositoryContract get current => resolve();

  /// Mevcut singleton — mock in-memory (lookup fallback).
  static AppointmentRepository get instance => AppointmentRepository.instance;

  /// Async randevu repository — smoke/ileride UI; backend + oturum koşullu.
  static AsyncAppointmentRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  /// Aktif async implementasyon Supabase mi?
  static bool get usesRemoteAppointments => _shouldUseRemoteAppointments();

  /// Sync resolver — UI kırılmaması için daima mock adapter.
  static AppointmentRepositoryContract resolve() {
    return MockAppointmentRepositoryAdapter();
  }

  static AsyncAppointmentRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteAppointments(),
      mockFactory: () => MockAsyncAppointmentRepositoryAdapter(),
      remoteFactory: () => SupabaseAppointmentRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncAppointmentRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteAppointments() {
    return AppointmentRepositoryBackendGate.shouldUseRemoteAppointments(
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

  static void clearTestOverrides() {
    testOverride = null;
  }
}
