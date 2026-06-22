import '../models/clinical_report.dart';
import 'clinical_report_list_load_result.dart';
import 'clinical_report_repository_failure.dart';
import 'clinical_report_repository_provider.dart';
import 'clinical_report_user_messages.dart';

abstract final class ClinicalReportListDataSource {
  static Future<ClinicalReportListLoadResult> load({
    String? patientId,
    String? query,
    ClinicalReportType? typeFilter,
    ClinicalReportStatus? statusFilter,
  }) async {
    try {
      final items = await ClinicalReportRepositoryProvider.asyncRepository
          .getFiltered(
        patientId: patientId,
        query: query,
        typeFilter: typeFilter,
        statusFilter: statusFilter,
      );
      return ClinicalReportListLoadResult.success(items);
    } on ClinicalReportRepositoryException catch (e) {
      return ClinicalReportListLoadResult.failure(
        ClinicalReportUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ClinicalReportListLoadResult.failure(
        ClinicalReportUserMessages.genericLoadFailure,
      );
    }
  }
}
