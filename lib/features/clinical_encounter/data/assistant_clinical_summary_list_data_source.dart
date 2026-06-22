import '../../../core/data/repository_registry.dart';
import '../../audit/access/clinical_access_audit_logger.dart';
import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_list_filters.dart';
import 'assistant_clinical_summary_list_load_result.dart';
import 'assistant_clinical_summary_list_user_messages.dart';
import 'assistant_clinical_summary_repository_failure.dart';
import 'clinical_summary_module_availability.dart';

/// Tanı özeti listesi — [RepositoryRegistry.assistantClinicalSummaries].
abstract final class AssistantClinicalSummaryListDataSource {
  static Future<AssistantClinicalSummaryListLoadResult> load({
    String? patientId,
    required String search,
  }) async {
    if (!ClinicalSummaryModuleAvailability.assistantOperational) {
      return AssistantClinicalSummaryListLoadResult.notConfigured();
    }

    try {
      final repo = RepositoryRegistry.assistantClinicalSummaries;
      final hasPatient = patientId != null && patientId.trim().isNotEmpty;

      List<AssistantClinicalSummary> list;
      if (hasPatient) {
        list = await repo.listAssistantClinicalSummaries(
          patientId: patientId!.trim(),
        );
      } else {
        list = await repo.listAssistantClinicalSummaries();
      }

      final sourceCount = list.length;
      list = AssistantClinicalSummaryListFilters.applySearch(list, search);
      list.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));

      ClinicalAccessAuditLogger.assistantSummaryList(
        patientId: patientId,
        resultCount: list.length,
      );
      return AssistantClinicalSummaryListLoadResult.success(
        list,
        sourceCountBeforeFilter: sourceCount,
      );
    } on AssistantClinicalSummaryRepositoryException catch (e) {
      final category =
          ClinicalAccessAuditLogger.categoryForAssistantSummaryFailure(
        e.reason,
      );
      if (e.reason == AssistantClinicalSummaryRepositoryFailure.notConfigured) {
        ClinicalAccessAuditLogger.assistantSummaryList(
          patientId: patientId,
          success: false,
          failureCategory: category,
        );
        return AssistantClinicalSummaryListLoadResult.notConfigured();
      }
      if (e.reason == AssistantClinicalSummaryRepositoryFailure.forbidden) {
        ClinicalAccessAuditLogger.permissionDenied(
          attemptedEventType: 'clinical.summary.assistant.list',
          failureCategory: category,
        );
      }
      ClinicalAccessAuditLogger.assistantSummaryList(
        patientId: patientId,
        success: false,
        failureCategory: category,
      );
      return AssistantClinicalSummaryListLoadResult.failure(
        AssistantClinicalSummaryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      ClinicalAccessAuditLogger.assistantSummaryList(
        patientId: patientId,
        success: false,
        failureCategory: 'unknown',
      );
      return AssistantClinicalSummaryListLoadResult.failure(
        AssistantClinicalSummaryListUserMessages.genericLoadFailure,
      );
    }
  }
}
