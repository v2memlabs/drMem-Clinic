import '../../../core/data/repository_registry.dart';
import '../../audit/access/clinical_access_audit_logger.dart';
import '../models/clinical_encounter.dart';
import '../models/physiotherapist_clinical_summary.dart';
import 'clinical_summary_module_availability.dart';
import 'physiotherapist_clinical_summary_list_filters.dart';
import 'physiotherapist_clinical_summary_list_load_result.dart';
import 'physiotherapist_clinical_summary_list_user_messages.dart';
import 'physiotherapist_clinical_summary_repository_failure.dart';

/// FTR klinik özet listesi — [RepositoryRegistry.physiotherapistClinicalSummaries].
abstract final class PhysiotherapistClinicalSummaryListDataSource {
  static Future<PhysiotherapistClinicalSummaryListLoadResult> load({
    String? patientId,
    required String search,
    ClinicalBodyRegion? regionFilter,
    ClinicalEncounterStatus? statusFilter,
  }) async {
    if (!ClinicalSummaryModuleAvailability.physiotherapistOperational) {
      return PhysiotherapistClinicalSummaryListLoadResult.notConfigured();
    }

    try {
      final repo = RepositoryRegistry.physiotherapistClinicalSummaries;
      final trimmedPatientId = patientId?.trim() ?? '';
      final hasPatient = trimmedPatientId.isNotEmpty;

      List<PhysiotherapistClinicalSummary> list;
      if (hasPatient) {
        list = await repo.listPhysiotherapistClinicalSummaries(
          patientId: trimmedPatientId,
        );
      } else {
        list = await repo.listPhysiotherapistClinicalSummaries();
      }

      final sourceCount = list.length;
      list = PhysiotherapistClinicalSummaryListFilters.apply(
        list,
        search: search,
        regionFilter: regionFilter,
        statusFilter: statusFilter,
      );
      list.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));

      ClinicalAccessAuditLogger.physiotherapistSummaryList(
        patientId: patientId,
        resultCount: list.length,
      );
      return PhysiotherapistClinicalSummaryListLoadResult.success(
        list,
        sourceCountBeforeFilter: sourceCount,
      );
    } on PhysiotherapistClinicalSummaryRepositoryException catch (e) {
      final category =
          ClinicalAccessAuditLogger.categoryForPhysiotherapistSummaryFailure(
        e.reason,
      );
      if (e.reason ==
          PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured) {
        ClinicalAccessAuditLogger.physiotherapistSummaryList(
          patientId: patientId,
          success: false,
          failureCategory: category,
        );
        return PhysiotherapistClinicalSummaryListLoadResult.notConfigured();
      }
      if (e.reason ==
          PhysiotherapistClinicalSummaryRepositoryFailure.forbidden) {
        ClinicalAccessAuditLogger.permissionDenied(
          attemptedEventType: 'clinical.summary.physiotherapist.list',
          failureCategory: category,
        );
      }
      ClinicalAccessAuditLogger.physiotherapistSummaryList(
        patientId: patientId,
        success: false,
        failureCategory: category,
      );
      return PhysiotherapistClinicalSummaryListLoadResult.failure(
        PhysiotherapistClinicalSummaryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      ClinicalAccessAuditLogger.physiotherapistSummaryList(
        patientId: patientId,
        success: false,
        failureCategory: 'unknown',
      );
      return PhysiotherapistClinicalSummaryListLoadResult.failure(
        PhysiotherapistClinicalSummaryListUserMessages.genericLoadFailure,
      );
    }
  }
}
