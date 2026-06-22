import '../../clinical_encounter/data/clinical_encounter_lookup_data_source.dart';
import '../../clinical_encounter/models/clinical_encounter.dart';
import '../../pdf_outputs/pdf_clinical_encounter_prefill.dart';

abstract final class RadiologyOrderEncounterPrefill {
  static Future<ClinicalEncounter?> loadEncounter(String? encounterId) async {
    final id = encounterId?.trim() ?? '';
    if (id.isEmpty) return null;
    return ClinicalEncounterLookupDataSource.findById(id);
  }

  static String diagnosisFromEncounter(ClinicalEncounter? encounter) {
    if (encounter == null) return '';
    return PdfClinicalEncounterPrefill.diagnosisLine(encounter);
  }

  static String? protocolFromEncounter(ClinicalEncounter? encounter) {
    if (encounter == null || !encounter.hasProtocolNumber) return null;
    return encounter.displayProtocolNumber;
  }
}
