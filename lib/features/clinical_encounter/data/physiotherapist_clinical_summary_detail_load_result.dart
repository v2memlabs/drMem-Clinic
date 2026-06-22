import '../models/physiotherapist_clinical_summary.dart';

/// FTR klinik özet detay yükleme sonucu.
class PhysiotherapistClinicalSummaryDetailLoadResult {
  final PhysiotherapistClinicalSummary? summary;
  final String? errorMessage;

  const PhysiotherapistClinicalSummaryDetailLoadResult._({
    this.summary,
    this.errorMessage,
  });

  factory PhysiotherapistClinicalSummaryDetailLoadResult.success(
    PhysiotherapistClinicalSummary summary,
  ) {
    return PhysiotherapistClinicalSummaryDetailLoadResult._(summary: summary);
  }

  factory PhysiotherapistClinicalSummaryDetailLoadResult.notFound() {
    return const PhysiotherapistClinicalSummaryDetailLoadResult._();
  }

  factory PhysiotherapistClinicalSummaryDetailLoadResult.failure(String message) {
    return PhysiotherapistClinicalSummaryDetailLoadResult._(
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
