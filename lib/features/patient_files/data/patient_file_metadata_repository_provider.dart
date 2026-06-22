import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'package:flutter/foundation.dart';

import 'mock_patient_file_metadata_repository.dart';
import 'patient_file_metadata_repository.dart';
import 'patient_file_metadata_repository_backend_gate.dart';
import 'patient_file_metadata_repository_stub.dart';
import 'supabase_patient_file_metadata_repository.dart';

/// Hasta dosya / PDF metadata repository çözümleyici.
///
/// Remote yalnızca [SupabasePatientFileMetadataRepository] seçer — Storage
/// upload/download, signed URL veya binary içerik bu provider'da yok.
abstract final class PatientFileMetadataRepositoryProvider {
  static PatientFileMetadataRepository? _cache;

  @visibleForTesting
  static PatientFileMetadataRepository? testOverride;

  static PatientFileMetadataRepository get repository {
    if (testOverride != null) return testOverride!;
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get usesRemotePatientFileMetadata =>
      _shouldUseRemotePatientFileMetadata();

  static PatientFileMetadataRepository _resolve() {
    if (_shouldUseRemotePatientFileMetadata()) {
      return SupabasePatientFileMetadataRepository.fromSupabase();
    }
    if (AppBackendConfig.isMock) {
      return MockPatientFileMetadataRepository();
    }
    return const PatientFileMetadataRepositoryStub();
  }

  static bool _shouldUseRemotePatientFileMetadata() {
    return PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPatientFileMetadataRoleEligible: _isPatientFileMetadataRoleEligible(),
    );
  }

  /// Doctor/admin + assistant (clinic_operations) + FTR (physiotherapy scope, RLS).
  /// Nurse: remote kapalı — `patient_files` SELECT RLS ile zaten 0 satır.
  static bool _isPatientFileMetadataRoleEligible() {
    return AuthSession.canViewFiles || AuthSession.canViewPhysiotherapy;
  }

  static void resetCache() {
    _cache = null;
  }
}
