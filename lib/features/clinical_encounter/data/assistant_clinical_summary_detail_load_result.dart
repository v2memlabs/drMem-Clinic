import '../models/assistant_clinical_summary.dart';

/// Assistant klinik özet detay yükleme sonucu.
class AssistantClinicalSummaryDetailLoadResult {
  final AssistantClinicalSummary? summary;
  final String? errorMessage;

  const AssistantClinicalSummaryDetailLoadResult._({
    this.summary,
    this.errorMessage,
  });

  factory AssistantClinicalSummaryDetailLoadResult.success(
    AssistantClinicalSummary summary,
  ) {
    return AssistantClinicalSummaryDetailLoadResult._(summary: summary);
  }

  factory AssistantClinicalSummaryDetailLoadResult.notFound() {
    return const AssistantClinicalSummaryDetailLoadResult._();
  }

  factory AssistantClinicalSummaryDetailLoadResult.failure(String message) {
    return AssistantClinicalSummaryDetailLoadResult._(
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
