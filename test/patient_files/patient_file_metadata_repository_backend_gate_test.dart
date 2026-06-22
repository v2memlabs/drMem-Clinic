import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_backend_gate.dart';

void main() {
  const infraReady = (
    isMockBackend: false,
    isSupabaseConfigured: true,
    isSupabaseInitialized: true,
    isLoggedIn: true,
    isSessionReady: true,
    hasActiveTenant: true,
  );

  group('PatientFileMetadataRepositoryBackendGate', () {
    test('remote when infra ready and role eligible', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: true,
        ),
        isTrue,
      );
    });

    test('false when mock backend', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: true,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isPatientFileMetadataRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when supabase not configured', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: false,
          isSupabaseConfigured: false,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isPatientFileMetadataRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when supabase not initialized', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: false,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when not logged in', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: false,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when session not ready', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: false,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when no active tenant', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: false,
          isPatientFileMetadataRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when nurse (role not eligible)', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: false,
        ),
        isFalse,
      );
    });

    test('true for doctor admin compatibility', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: true,
        ),
        isTrue,
      );
    });

    test('true for physiotherapist via role flag (RLS limits scope)', () {
      expect(
        PatientFileMetadataRepositoryBackendGate.canUsePatientFileMetadataRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPatientFileMetadataRoleEligible: true,
        ),
        isTrue,
      );
    });
  });
}
