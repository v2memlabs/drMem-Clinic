import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_backend_gate.dart';

void main() {
  const infraReady = (
    isMockBackend: false,
    isSupabaseConfigured: true,
    isSupabaseInitialized: true,
    isLoggedIn: true,
    isSessionReady: true,
    hasActiveTenant: true,
  );

  group('ClinicalRoleSummaryRepositoryBackendGate — assistant', () {
    test('remote when infra ready and assistant role eligible', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isAssistantSummaryRoleEligible: true,
        ),
        isTrue,
      );
    });

    test('false when mock backend', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: true,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isAssistantSummaryRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when supabase not configured', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: false,
          isSupabaseConfigured: false,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isAssistantSummaryRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when not logged in', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: false,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isAssistantSummaryRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when session not ready', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: false,
          hasActiveTenant: infraReady.hasActiveTenant,
          isAssistantSummaryRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when no active tenant', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: false,
          isAssistantSummaryRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('false when nurse (role not eligible)', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isAssistantSummaryRoleEligible: false,
        ),
        isFalse,
      );
    });

    test('true for doctor admin compatibility', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate.canUseAssistantClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isAssistantSummaryRoleEligible: true,
        ),
        isTrue,
      );
    });
  });

  group('ClinicalRoleSummaryRepositoryBackendGate — physiotherapist', () {
    test('remote when infra ready and physio role eligible', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate
            .canUsePhysiotherapistClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPhysiotherapistSummaryRoleEligible: true,
        ),
        isTrue,
      );
    });

    test('false when nurse (role not eligible)', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate
            .canUsePhysiotherapistClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPhysiotherapistSummaryRoleEligible: false,
        ),
        isFalse,
      );
    });

    test('false when assistant only (physio gate)', () {
      expect(
        ClinicalRoleSummaryRepositoryBackendGate
            .canUsePhysiotherapistClinicalSummaryRemote(
          isMockBackend: infraReady.isMockBackend,
          isSupabaseConfigured: infraReady.isSupabaseConfigured,
          isSupabaseInitialized: infraReady.isSupabaseInitialized,
          isLoggedIn: infraReady.isLoggedIn,
          isSessionReady: infraReady.isSessionReady,
          hasActiveTenant: infraReady.hasActiveTenant,
          isPhysiotherapistSummaryRoleEligible: false,
        ),
        isFalse,
      );
    });
  });
}
