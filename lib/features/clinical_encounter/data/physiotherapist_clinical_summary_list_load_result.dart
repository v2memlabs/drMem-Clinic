import '../models/physiotherapist_clinical_summary.dart';

/// FTR klinik özet listesi yükleme sonucu.
class PhysiotherapistClinicalSummaryListLoadResult {
  final List<PhysiotherapistClinicalSummary> summaries;
  final String? errorMessage;
  final int sourceCountBeforeFilter;
  final bool isNotConfigured;

  const PhysiotherapistClinicalSummaryListLoadResult._({
    required this.summaries,
    this.errorMessage,
    this.sourceCountBeforeFilter = 0,
    this.isNotConfigured = false,
  });

  factory PhysiotherapistClinicalSummaryListLoadResult.success(
    List<PhysiotherapistClinicalSummary> summaries, {
    required int sourceCountBeforeFilter,
  }) {
    return PhysiotherapistClinicalSummaryListLoadResult._(
      summaries: summaries,
      sourceCountBeforeFilter: sourceCountBeforeFilter,
    );
  }

  factory PhysiotherapistClinicalSummaryListLoadResult.notConfigured() {
    return const PhysiotherapistClinicalSummaryListLoadResult._(
      summaries: [],
      isNotConfigured: true,
    );
  }

  factory PhysiotherapistClinicalSummaryListLoadResult.failure(String message) {
    return PhysiotherapistClinicalSummaryListLoadResult._(
      summaries: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
