import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_backend_gate.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_async_clinical_encounter_repository_adapter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/supabase_async_clinical_encounter_repository_stub.dart';

void main() {
  tearDown(ClinicalEncounterRepositoryProvider.resetCache);

  const allGatesPass = (
    isMockBackend: false,
    isSupabaseConfigured: true,
    isSupabaseInitialized: true,
    isLoggedIn: true,
    isSessionReady: true,
    hasActiveTenant: true,
  );

  group('ClinicalEncounterRepositoryBackendGate', () {
    test('remote when all gates pass and doctor full-table eligible', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: allGatesPass.isMockBackend,
          isSupabaseConfigured: allGatesPass.isSupabaseConfigured,
          isSupabaseInitialized: allGatesPass.isSupabaseInitialized,
          isLoggedIn: allGatesPass.isLoggedIn,
          isSessionReady: allGatesPass.isSessionReady,
          hasActiveTenant: allGatesPass.hasActiveTenant,
          isDoctorFullTableEligible: true,
        ),
        isTrue,
      );
    });

    test('mock when backend is mock', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: true,
          isSupabaseConfigured: allGatesPass.isSupabaseConfigured,
          isSupabaseInitialized: allGatesPass.isSupabaseInitialized,
          isLoggedIn: allGatesPass.isLoggedIn,
          isSessionReady: allGatesPass.isSessionReady,
          hasActiveTenant: allGatesPass.hasActiveTenant,
          isDoctorFullTableEligible: true,
        ),
        isFalse,
      );
    });

    test('mock when supabase not configured', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: false,
          isSupabaseConfigured: false,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isDoctorFullTableEligible: true,
        ),
        isFalse,
      );
    });

    test('mock when no active tenant', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: false,
          isDoctorFullTableEligible: true,
        ),
        isFalse,
      );
    });

    test('mock when not doctor full-table eligible (assistant)', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isDoctorFullTableEligible: false,
        ),
        isFalse,
      );
    });

    test('mock for physiotherapist role gate', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isDoctorFullTableEligible: false,
        ),
        isFalse,
      );
    });

    test('mock for nurse role gate', () {
      expect(
        ClinicalEncounterRepositoryBackendGate.shouldUseRemoteClinicalEncounters(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isDoctorFullTableEligible: false,
        ),
        isFalse,
      );
    });
  });

  group('ClinicalEncounterRepositoryProvider', () {
    test('instance exposes sync mock singleton unchanged', () {
      expect(
        ClinicalEncounterRepositoryProvider.instance,
        same(ClinicalEncounterRepository.instance),
      );
    });

    test('async uses mock adapter when mock backend', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ClinicalEncounterRepositoryProvider.resetCache();
      expect(
        ClinicalEncounterRepositoryProvider.asyncRepository,
        isA<MockAsyncClinicalEncounterRepositoryAdapter>(),
      );
      expect(
        ClinicalEncounterRepositoryProvider.usesRemoteClinicalEncounters,
        isFalse,
      );
    });

    test('async uses unavailable stub when supabase backend but gate fails', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      ClinicalEncounterRepositoryProvider.resetCache();
      expect(
        ClinicalEncounterRepositoryProvider.asyncRepository,
        isA<SupabaseAsyncClinicalEncounterRepositoryStub>(),
      );
      expect(
        ClinicalEncounterRepositoryProvider.usesRemoteClinicalEncounters,
        isFalse,
      );
    });

    test('default backend resolves to mock async', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ClinicalEncounterRepositoryProvider.resetCache();
      expect(
        ClinicalEncounterRepositoryProvider.asyncRepository,
        isA<MockAsyncClinicalEncounterRepositoryAdapter>(),
      );
    });
  });
}
