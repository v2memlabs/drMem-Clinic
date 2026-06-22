import '../models/clinical_report.dart';

class ClinicalReportListLoadResult {
  final List<ClinicalReport> items;
  final String? errorMessage;

  const ClinicalReportListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory ClinicalReportListLoadResult.success(List<ClinicalReport> items) {
    return ClinicalReportListLoadResult._(items: items);
  }

  factory ClinicalReportListLoadResult.failure(String message) {
    return ClinicalReportListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
