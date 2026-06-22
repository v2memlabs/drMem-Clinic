import '../../../core/data/repository_registry.dart';
import '../models/clinical_encounter.dart';
import 'clinical_encounter_list_data_source.dart';
import 'clinical_encounter_list_load_result.dart';

/// Hasta detayı muayene önizlemesi — async registry hattı.
abstract final class ClinicalEncounterPatientDetailDataSource {
  static Future<ClinicalEncounterListLoadResult> load(String patientId) {
    return ClinicalEncounterListDataSource.load(
      patientId: patientId,
      search: '',
      usesRemote: RepositoryRegistry.usesRemoteClinicalEncounters,
    );
  }

  static List<ClinicalEncounter> sortedNewestFirst(
    List<ClinicalEncounter> encounters,
  ) {
    final list = List<ClinicalEncounter>.from(encounters);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static ClinicalEncounter? latest(List<ClinicalEncounter> encounters) {
    final sorted = sortedNewestFirst(encounters);
    if (sorted.isEmpty) return null;
    return sorted.first;
  }
}
