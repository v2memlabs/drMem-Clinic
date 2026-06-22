import '../models/clinical_encounter.dart';

/// [ClinicalDiagnosisType] ↔ `clinical_data.diagnosis.type` stabil string.
abstract final class ClinicalDiagnosisTypeMapping {
  static String toDb(ClinicalDiagnosisType type) {
    switch (type) {
      case ClinicalDiagnosisType.travmatik:
        return 'traumatic';
      case ClinicalDiagnosisType.dejeneratif:
        return 'degenerative';
      case ClinicalDiagnosisType.asiriKullanim:
        return 'overuse';
      case ClinicalDiagnosisType.postOp:
        return 'post_op';
      case ClinicalDiagnosisType.inflamatuvar:
        return 'inflammatory';
      case ClinicalDiagnosisType.diger:
        return 'other';
    }
  }

  static ClinicalDiagnosisType fromDb(String? value) {
    switch (value?.trim()) {
      case 'traumatic':
        return ClinicalDiagnosisType.travmatik;
      case 'degenerative':
        return ClinicalDiagnosisType.dejeneratif;
      case 'overuse':
        return ClinicalDiagnosisType.asiriKullanim;
      case 'post_op':
        return ClinicalDiagnosisType.postOp;
      case 'inflammatory':
        return ClinicalDiagnosisType.inflamatuvar;
      case 'other':
        return ClinicalDiagnosisType.diger;
      default:
        return ClinicalDiagnosisType.diger;
    }
  }
}
