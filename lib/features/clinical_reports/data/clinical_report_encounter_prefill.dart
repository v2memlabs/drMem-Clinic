import '../../clinical_encounter/data/clinical_encounter_lookup_data_source.dart';
import '../../clinical_encounter/models/clinical_encounter.dart';
import '../../pdf_outputs/pdf_clinical_encounter_prefill.dart';
import '../models/clinical_report.dart';

abstract final class ClinicalReportEncounterPrefill {
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

  static ClinicalReportType? parseReportType(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return null;
    for (final type in ClinicalReportType.values) {
      if (type.name.toLowerCase() == value) return type;
    }
    return null;
  }
}
