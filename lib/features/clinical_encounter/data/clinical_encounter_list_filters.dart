import '../models/clinical_encounter.dart';

/// Muayene listesi — client-side filtre (remote v1: sunucu sonrası).
abstract final class ClinicalEncounterListFilters {
  static List<ClinicalEncounter> applyVisitType(
    List<ClinicalEncounter> list,
    ClinicalVisitType? visit,
  ) {
    if (visit == null) return list;
    return list.where((e) => e.visitType == visit).toList();
  }

  static List<ClinicalEncounter> applyStatus(
    List<ClinicalEncounter> list,
    ClinicalEncounterStatus? status,
  ) {
    if (status == null) return list;
    return list.where((e) => e.status == status).toList();
  }

  static List<ClinicalEncounter> applyBodyRegion(
    List<ClinicalEncounter> list,
    ClinicalBodyRegion? region,
  ) {
    if (region == null) return list;
    return list.where((e) => e.bodyRegion == region).toList();
  }

  /// Mock mod arama — mevcut sync liste davranışı (şikayet, bölge dahil).
  static List<ClinicalEncounter> applyMockSearch(
    List<ClinicalEncounter> list,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((e) {
      if (e.patientName.toLowerCase().contains(q)) return true;
      if (e.chiefComplaint.toLowerCase().contains(q)) return true;
      if (e.bodyRegion.label.toLowerCase().contains(q)) return true;
      if (e.preliminaryDiagnosis.toLowerCase().contains(q)) return true;
      if (e.treatmentPlanSummary.toLowerCase().contains(q)) return true;
      if (e.icdCode.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }
}
