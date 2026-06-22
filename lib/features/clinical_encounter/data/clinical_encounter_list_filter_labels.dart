import '../models/clinical_encounter.dart';

/// Muayene listesi filtre dropdown’ları — kısa UI etiketleri (domain enum değişmez).
abstract final class ClinicalEncounterListFilterLabels {
  static String visitType(ClinicalVisitType type) {
    switch (type) {
      case ClinicalVisitType.ilkMuayene:
        return 'İlk Muayene';
      case ClinicalVisitType.kontrol:
        return 'Kontrol';
      case ClinicalVisitType.postOpKontrol:
        return 'Post-op Kontrol';
      case ClinicalVisitType.ikinciGorus:
        return 'İkinci Görüş';
      case ClinicalVisitType.girisimOncesiDegerlendirme:
        return 'Girişim Önc. Değ.';
      case ClinicalVisitType.genelOrtopedikDegerlendirme:
        return 'Genel Ort. Değ.';
    }
  }

  static String status(ClinicalEncounterStatus status) {
    switch (status) {
      case ClinicalEncounterStatus.taslak:
        return 'Taslak';
      case ClinicalEncounterStatus.tamamlandi:
        return 'Tamamlandı';
      case ClinicalEncounterStatus.kontrolPlanlandi:
        return 'Kontrol Planı';
      case ClinicalEncounterStatus.fizyoterapiyeYonlendirildi:
        return 'FTR Yönlendirildi';
      case ClinicalEncounterStatus.ameliyatPlanlandi:
        return 'Ameliyat Planı';
    }
  }
}
