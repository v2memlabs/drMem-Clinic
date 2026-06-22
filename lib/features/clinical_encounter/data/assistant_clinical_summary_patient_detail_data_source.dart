import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_list_data_source.dart';
import 'assistant_clinical_summary_list_load_result.dart';

/// Hasta detayı asistan klinik özet önizlemesi — güvenli özet hattı.
abstract final class AssistantClinicalSummaryPatientDetailDataSource {
  static Future<AssistantClinicalSummaryListLoadResult> load(String patientId) {
    return AssistantClinicalSummaryListDataSource.load(
      patientId: patientId,
      search: '',
    );
  }

  static List<AssistantClinicalSummary> sortedNewestFirst(
    List<AssistantClinicalSummary> summaries,
  ) {
    final list = List<AssistantClinicalSummary>.from(summaries);
    list.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
    return list;
  }

  static AssistantClinicalSummary? latest(
    List<AssistantClinicalSummary> summaries,
  ) {
    final sorted = sortedNewestFirst(summaries);
    if (sorted.isEmpty) return null;
    return sorted.first;
  }
}
