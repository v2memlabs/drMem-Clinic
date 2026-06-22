import '../models/clinical_encounter.dart';

/// [ClinicalEncounterStatus] ↔ Supabase `status` text.
abstract final class ClinicalEncounterStatusMapping {
  static const String draft = 'draft';
  static const String completed = 'completed';
  static const String controlPlanned = 'control_planned';
  static const String physiotherapyReferred = 'physiotherapy_referred';
  static const String surgeryPlanned = 'surgery_planned';

  static String toDb(ClinicalEncounterStatus status) {
    switch (status) {
      case ClinicalEncounterStatus.taslak:
        return draft;
      case ClinicalEncounterStatus.tamamlandi:
        return completed;
      case ClinicalEncounterStatus.kontrolPlanlandi:
        return controlPlanned;
      case ClinicalEncounterStatus.fizyoterapiyeYonlendirildi:
        return physiotherapyReferred;
      case ClinicalEncounterStatus.ameliyatPlanlandi:
        return surgeryPlanned;
    }
  }

  static ClinicalEncounterStatus fromDb(String? value) {
    switch (value?.trim()) {
      case draft:
        return ClinicalEncounterStatus.taslak;
      case completed:
        return ClinicalEncounterStatus.tamamlandi;
      case controlPlanned:
        return ClinicalEncounterStatus.kontrolPlanlandi;
      case physiotherapyReferred:
        return ClinicalEncounterStatus.fizyoterapiyeYonlendirildi;
      case surgeryPlanned:
        return ClinicalEncounterStatus.ameliyatPlanlandi;
      default:
        return ClinicalEncounterStatus.taslak;
    }
  }
}
