import '../models/clinical_encounter.dart';
import 'clinical_encounter_ownership.dart';
import 'mock_clinical_encounters.dart';

class ClinicalEncounterRepository {
  ClinicalEncounterRepository._();

  static final ClinicalEncounterRepository instance = ClinicalEncounterRepository._();

  List<ClinicalEncounter> _visible(Iterable<ClinicalEncounter> source) =>
      source.where(ClinicalEncounterOwnership.isVisibleToCurrentUser).toList();

  List<ClinicalEncounter> getAll() =>
      List.unmodifiable(_visible(mockClinicalEncounters));

  ClinicalEncounter? getById(String id) {
    for (final e in mockClinicalEncounters) {
      if (e.id == id && ClinicalEncounterOwnership.isVisibleToCurrentUser(e)) {
        return e;
      }
    }
    return null;
  }

  List<ClinicalEncounter> getByPatientId(String patientId) {
    final list = _visible(
      mockClinicalEncounters.where((e) => e.patientId == patientId),
    );
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Hastanın en güncel muayene kaydı ([createdAt] en yeni).
  ClinicalEncounter? getLatestByPatientId(String patientId) {
    final list = getByPatientId(patientId);
    return list.isEmpty ? null : list.first;
  }

  List<ClinicalEncounter> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _visible(mockClinicalEncounters.where((e) {
      if (e.protocolNumber.toLowerCase().contains(q)) return true;
      if (e.patientName.toLowerCase().contains(q)) return true;
      if (e.chiefComplaint.toLowerCase().contains(q)) return true;
      if (e.bodyRegion.label.toLowerCase().contains(q)) return true;
      if (e.preliminaryDiagnosis.toLowerCase().contains(q)) return true;
      if (e.treatmentPlanSummary.toLowerCase().contains(q)) return true;
      return false;
    }));
  }

  void add(ClinicalEncounter encounter) => mockClinicalEncounters.insert(0, encounter);

  bool update(ClinicalEncounter updatedEncounter) {
    final index = mockClinicalEncounters.indexWhere((e) => e.id == updatedEncounter.id);
    if (index < 0) return false;
    mockClinicalEncounters[index] = updatedEncounter;
    return true;
  }
}
