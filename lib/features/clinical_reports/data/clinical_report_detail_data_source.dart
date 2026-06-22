import '../models/clinical_report.dart';
import 'clinical_report_repository_failure.dart';
import 'clinical_report_repository_provider.dart';
import 'clinical_report_user_messages.dart';

class ClinicalReportDetailLoadResult {
  final ClinicalReport? report;
  final String? errorMessage;

  const ClinicalReportDetailLoadResult._({
    this.report,
    this.errorMessage,
  });

  factory ClinicalReportDetailLoadResult.success(ClinicalReport report) {
    return ClinicalReportDetailLoadResult._(report: report);
  }

  factory ClinicalReportDetailLoadResult.failure(String message) {
    return ClinicalReportDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class ClinicalReportDetailDataSource {
  static Future<ClinicalReportDetailLoadResult> load(String id) async {
    try {
      final report =
          await ClinicalReportRepositoryProvider.asyncRepository.getById(id);
      if (report == null) {
        return ClinicalReportDetailLoadResult.failure(
          ClinicalReportUserMessages.notFound,
        );
      }
      return ClinicalReportDetailLoadResult.success(report);
    } on ClinicalReportRepositoryException catch (e) {
      return ClinicalReportDetailLoadResult.failure(
        ClinicalReportUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ClinicalReportDetailLoadResult.failure(
        ClinicalReportUserMessages.genericLoadFailure,
      );
    }
  }
}
