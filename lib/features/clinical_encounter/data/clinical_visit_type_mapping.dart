import '../models/clinical_encounter.dart';

/// [ClinicalVisitType] ↔ Supabase `visit_type` text.
abstract final class ClinicalVisitTypeMapping {
  static const String firstVisit = 'first_visit';
  static const String followUp = 'follow_up';
  static const String postOpFollowUp = 'post_op_follow_up';
  static const String secondOpinion = 'second_opinion';
  static const String preProcedureEval = 'pre_procedure_eval';
  static const String generalOrthopedicEval = 'general_orthopedic_eval';

  static String toDb(ClinicalVisitType type) {
    switch (type) {
      case ClinicalVisitType.ilkMuayene:
        return firstVisit;
      case ClinicalVisitType.kontrol:
        return followUp;
      case ClinicalVisitType.postOpKontrol:
        return postOpFollowUp;
      case ClinicalVisitType.ikinciGorus:
        return secondOpinion;
      case ClinicalVisitType.girisimOncesiDegerlendirme:
        return preProcedureEval;
      case ClinicalVisitType.genelOrtopedikDegerlendirme:
        return generalOrthopedicEval;
    }
  }

  static ClinicalVisitType fromDb(String? value) {
    switch (value?.trim()) {
      case firstVisit:
        return ClinicalVisitType.ilkMuayene;
      case followUp:
        return ClinicalVisitType.kontrol;
      case postOpFollowUp:
        return ClinicalVisitType.postOpKontrol;
      case secondOpinion:
        return ClinicalVisitType.ikinciGorus;
      case preProcedureEval:
        return ClinicalVisitType.girisimOncesiDegerlendirme;
      case generalOrthopedicEval:
        return ClinicalVisitType.genelOrtopedikDegerlendirme;
      default:
        return ClinicalVisitType.genelOrtopedikDegerlendirme;
    }
  }
}
