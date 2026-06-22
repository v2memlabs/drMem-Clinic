import '../../../core/data/repository_registry.dart';
import '../../audit/access/clinical_access_audit_logger.dart';
import 'assistant_clinical_summary_detail_load_result.dart';
import 'assistant_clinical_summary_detail_user_messages.dart';
import 'assistant_clinical_summary_repository_failure.dart';

/// Tanı özeti detay — [RepositoryRegistry.assistantClinicalSummaries].
abstract final class AssistantClinicalSummaryDetailDataSource {
  static Future<AssistantClinicalSummaryDetailLoadResult> loadById(
    String encounterId,
  ) async {
    final trimmed = encounterId.trim();
    if (trimmed.isEmpty) {
      return AssistantClinicalSummaryDetailLoadResult.notFound();
    }

    try {
      final summary = await RepositoryRegistry.assistantClinicalSummaries
          .getAssistantClinicalSummary(trimmed);
      if (summary == null) {
        return AssistantClinicalSummaryDetailLoadResult.notFound();
      }
      ClinicalAccessAuditLogger.assistantSummaryView(
        encounterId: summary.encounterId,
        patientId: summary.patientId,
      );
      return AssistantClinicalSummaryDetailLoadResult.success(summary);
    } on AssistantClinicalSummaryRepositoryException catch (e) {
      if (e.reason == AssistantClinicalSummaryRepositoryFailure.notFound) {
        return AssistantClinicalSummaryDetailLoadResult.notFound();
      }
      final category =
          ClinicalAccessAuditLogger.categoryForAssistantSummaryFailure(
        e.reason,
      );
      if (e.reason == AssistantClinicalSummaryRepositoryFailure.forbidden) {
        ClinicalAccessAuditLogger.permissionDenied(
          attemptedEventType: 'clinical.summary.assistant.view',
          failureCategory: category,
        );
      }
      ClinicalAccessAuditLogger.assistantSummaryView(
        encounterId: trimmed,
        success: false,
        failureCategory: category,
      );
      return AssistantClinicalSummaryDetailLoadResult.failure(
        AssistantClinicalSummaryDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      ClinicalAccessAuditLogger.assistantSummaryView(
        encounterId: trimmed,
        success: false,
        failureCategory: 'unknown',
      );
      return AssistantClinicalSummaryDetailLoadResult.failure(
        AssistantClinicalSummaryDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
