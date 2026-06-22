import '../models/assistant_clinical_summary.dart';



/// Assistant klinik özet listesi yükleme sonucu.

class AssistantClinicalSummaryListLoadResult {

  final List<AssistantClinicalSummary> summaries;

  final String? errorMessage;

  final int sourceCountBeforeFilter;

  final bool isNotConfigured;



  const AssistantClinicalSummaryListLoadResult._({

    required this.summaries,

    this.errorMessage,

    this.sourceCountBeforeFilter = 0,

    this.isNotConfigured = false,

  });



  factory AssistantClinicalSummaryListLoadResult.success(

    List<AssistantClinicalSummary> summaries, {

    required int sourceCountBeforeFilter,

  }) {

    return AssistantClinicalSummaryListLoadResult._(

      summaries: summaries,

      sourceCountBeforeFilter: sourceCountBeforeFilter,

    );

  }



  factory AssistantClinicalSummaryListLoadResult.notConfigured() {

    return const AssistantClinicalSummaryListLoadResult._(

      summaries: [],

      isNotConfigured: true,

    );

  }



  factory AssistantClinicalSummaryListLoadResult.failure(String message) {

    return AssistantClinicalSummaryListLoadResult._(

      summaries: const [],

      errorMessage: message,

    );

  }



  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

}

