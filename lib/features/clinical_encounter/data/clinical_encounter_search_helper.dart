import '../models/clinical_encounter.dart';

/// Remote v1 arama — MVP client-side filtre ([internalDoctorNote] hariç).
abstract final class ClinicalEncounterSearchHelper {
  static List<ClinicalEncounter> filter(
    List<ClinicalEncounter> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source.where((e) => _matches(e, q)).toList();
  }

  static bool _matches(ClinicalEncounter e, String q) {
    if (e.protocolNumber.toLowerCase().contains(q)) return true;
    if (e.patientName.toLowerCase().contains(q)) return true;
    if (e.preliminaryDiagnosis.toLowerCase().contains(q)) return true;
    if (e.finalDiagnosis.toLowerCase().contains(q)) return true;
    if (e.icdCode.toLowerCase().contains(q)) return true;
    if (e.icdTitle.toLowerCase().contains(q)) return true;
    if (e.planTitle.toLowerCase().contains(q)) return true;
    if (e.conservativeTreatment.toLowerCase().contains(q)) return true;
    if (e.differentialDiagnosis.toLowerCase().contains(q)) return true;
    if (e.clinicalImpression.toLowerCase().contains(q)) return true;
    return false;
  }
}
