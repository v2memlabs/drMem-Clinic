import '../../../core/data/repository_registry.dart';
import '../../audit/access/clinical_access_audit_logger.dart';
import 'physiotherapist_clinical_summary_detail_load_result.dart';
import 'physiotherapist_clinical_summary_detail_user_messages.dart';
import 'physiotherapist_clinical_summary_repository_failure.dart';

/// FTR klinik özet detay — [RepositoryRegistry.physiotherapistClinicalSummaries].
abstract final class PhysiotherapistClinicalSummaryDetailDataSource {
  static Future<PhysiotherapistClinicalSummaryDetailLoadResult> loadById(
    String encounterId,
  ) async {
    final trimmed = encounterId.trim();
    if (trimmed.isEmpty) {
      return PhysiotherapistClinicalSummaryDetailLoadResult.notFound();
    }

    try {
      final summary = await RepositoryRegistry.physiotherapistClinicalSummaries
          .getPhysiotherapistClinicalSummary(trimmed);
      if (summary == null) {
        return PhysiotherapistClinicalSummaryDetailLoadResult.notFound();
      }
      ClinicalAccessAuditLogger.physiotherapistSummaryView(
        encounterId: summary.encounterId,
        patientId: summary.patientId,
      );
      return PhysiotherapistClinicalSummaryDetailLoadResult.success(summary);
    } on PhysiotherapistClinicalSummaryRepositoryException catch (e) {
      if (e.reason == PhysiotherapistClinicalSummaryRepositoryFailure.notFound) {
        return PhysiotherapistClinicalSummaryDetailLoadResult.notFound();
      }
      final category =
          ClinicalAccessAuditLogger.categoryForPhysiotherapistSummaryFailure(
        e.reason,
      );
      if (e.reason ==
          PhysiotherapistClinicalSummaryRepositoryFailure.forbidden) {
        ClinicalAccessAuditLogger.permissionDenied(
          attemptedEventType: 'clinical.summary.physiotherapist.view',
          failureCategory: category,
        );
      }
      ClinicalAccessAuditLogger.physiotherapistSummaryView(
        encounterId: trimmed,
        success: false,
        failureCategory: category,
      );
      return PhysiotherapistClinicalSummaryDetailLoadResult.failure(
        PhysiotherapistClinicalSummaryDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      ClinicalAccessAuditLogger.physiotherapistSummaryView(
        encounterId: trimmed,
        success: false,
        failureCategory: 'unknown',
      );
      return PhysiotherapistClinicalSummaryDetailLoadResult.failure(
        PhysiotherapistClinicalSummaryDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
