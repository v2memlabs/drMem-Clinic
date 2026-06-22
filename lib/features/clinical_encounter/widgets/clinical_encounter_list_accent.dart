import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/clinical_encounter.dart';

/// Muayene listesi kartı sol renk şeridi — tip/durum görsel ayrımı.
abstract final class ClinicalEncounterListAccent {
  static const Color postOpOrange = Color(0xFFE67E22);
  static const Color controlYellow = Color(0xFFF9A825);
  static const Color urgentRed = Color(0xFFC62828);

  static Color colorFor(ClinicalEncounter encounter) {
    if (encounter.physiotherapyReferral ||
        encounter.status == ClinicalEncounterStatus.fizyoterapiyeYonlendirildi) {
      return AppColors.navy;
    }

    switch (encounter.visitType) {
      case ClinicalVisitType.ilkMuayene:
        return AppColors.accentTurquoise;
      case ClinicalVisitType.postOpKontrol:
        return postOpOrange;
      case ClinicalVisitType.kontrol:
        return controlYellow;
      case ClinicalVisitType.girisimOncesiDegerlendirme:
        return urgentRed;
      case ClinicalVisitType.ikinciGorus:
      case ClinicalVisitType.genelOrtopedikDegerlendirme:
        return AppColors.accentTurquoise;
    }
  }
}
