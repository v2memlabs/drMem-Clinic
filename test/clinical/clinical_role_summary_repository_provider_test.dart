import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_async_clinical_encounter_repository_adapter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_physiotherapist_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/supabase_assistant_clinical_summary_repository_stub.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/supabase_physiotherapist_clinical_summary_repository_stub.dart';

void main() {
  tearDown(() {
    ClinicalRoleSummaryRepositoryProvider.clearTestOverrides();
    ClinicalRoleSummaryRepositoryProvider.resetCache();
  });

  group('ClinicalRoleSummaryRepositoryProvider', () {
    test('mock backend uses allowlist mock assistant repository', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ClinicalRoleSummaryRepositoryProvider.resetCache();

      expect(
        ClinicalRoleSummaryRepositoryProvider.assistantRepository,
        isA<MockAssistantClinicalSummaryRepository>(),
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider.physiotherapistRepository,
        isA<MockPhysiotherapistClinicalSummaryRepository>(),
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider.usesRemoteAssistantClinicalSummaries,
        isFalse,
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider
            .usesRemotePhysiotherapistClinicalSummaries,
        isFalse,
      );
    });

    test('supabase backend without init uses stubs not full clinical', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      ClinicalRoleSummaryRepositoryProvider.resetCache();

      expect(
        ClinicalRoleSummaryRepositoryProvider.assistantRepository,
        isA<SupabaseAssistantClinicalSummaryRepositoryStub>(),
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider.physiotherapistRepository,
        isA<SupabasePhysiotherapistClinicalSummaryRepositoryStub>(),
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider.usesRemoteAssistantClinicalSummaries,
        isFalse,
      );
    });

    test('assistantTestOverride bypasses resolved repository', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ClinicalRoleSummaryRepositoryProvider.resetCache();

      final override = const MockAssistantClinicalSummaryRepository();
      ClinicalRoleSummaryRepositoryProvider.assistantTestOverride = override;

      expect(
        ClinicalRoleSummaryRepositoryProvider.assistantRepository,
        same(override),
      );
    });

    test('assistant repository is not ClinicalEncounter async adapter', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ClinicalRoleSummaryRepositoryProvider.resetCache();

      expect(
        ClinicalRoleSummaryRepositoryProvider.assistantRepository,
        isA<AssistantClinicalSummaryRepository>(),
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider.assistantRepository,
        isNot(isA<MockAsyncClinicalEncounterRepositoryAdapter>()),
      );
    });

    test('physiotherapist repository is not ClinicalEncounter async adapter', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ClinicalRoleSummaryRepositoryProvider.resetCache();

      expect(
        ClinicalRoleSummaryRepositoryProvider.physiotherapistRepository,
        isA<PhysiotherapistClinicalSummaryRepository>(),
      );
      expect(
        ClinicalRoleSummaryRepositoryProvider.physiotherapistRepository,
        isNot(isA<MockAsyncClinicalEncounterRepositoryAdapter>()),
      );
    });
  });
}
