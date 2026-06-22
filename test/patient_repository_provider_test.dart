import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/patients/data/mock_async_patient_repository_adapter.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patient_repository_adapter.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_backend_gate.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart'
    show PatientRepositoryException, PatientRepositoryFailure;
import 'package:v2mem_clinic/features/patients/data/patient_repository_provider.dart';
import 'package:v2mem_clinic/features/patients/data/supabase_async_patient_repository_stub.dart';

void main() {
  tearDown(PatientRepositoryProvider.resetCache);

  group('PatientRepositoryBackendGate', () {
    test('remote when all gates pass', () {
      expect(
        PatientRepositoryBackendGate.shouldUseRemotePatients(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
        ),
        isTrue,
      );
    });

    test('mock when backend is mock', () {
      expect(
        PatientRepositoryBackendGate.shouldUseRemotePatients(
          isMockBackend: true,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
        ),
        isFalse,
      );
    });

    test('mock when no active tenant', () {
      expect(
        PatientRepositoryBackendGate.shouldUseRemotePatients(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: false,
        ),
        isFalse,
      );
    });

    test('mock when supabase not configured', () {
      expect(
        PatientRepositoryBackendGate.shouldUseRemotePatients(
          isMockBackend: false,
          isSupabaseConfigured: false,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
        ),
        isFalse,
      );
    });
  });

  group('PatientRepositoryProvider', () {
    test('sync current always mock adapter', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      expect(PatientRepositoryProvider.current, isA<MockPatientRepositoryAdapter>());
      expect(PatientRepositoryProvider.resolve(), isA<MockPatientRepositoryAdapter>());
    });

    test('async uses mock adapter when mock backend', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientRepositoryProvider.resetCache();
      expect(
        PatientRepositoryProvider.asyncRepository,
        isA<MockAsyncPatientRepositoryAdapter>(),
      );
      expect(PatientRepositoryProvider.usesRemotePatients, isFalse);
    });

    test('async uses unavailable stub when supabase backend but gate fails', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      PatientRepositoryProvider.resetCache();
      expect(
        PatientRepositoryProvider.asyncRepository,
        isA<SupabaseAsyncPatientRepositoryStub>(),
      );
      expect(PatientRepositoryProvider.usesRemotePatients, isFalse);
    });

    test('unavailable stub read throws notConfigured', () async {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      PatientRepositoryProvider.resetCache();
      final repo = PatientRepositoryProvider.asyncRepository;

      await expectLater(
        repo.getAll(),
        throwsA(
          isA<PatientRepositoryException>().having(
            (e) => e.reason,
            'reason',
            PatientRepositoryFailure.notConfigured,
          ),
        ),
      );
    });
  });
}
