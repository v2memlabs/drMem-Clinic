import '../models/clinical_encounter.dart';

/// [ClinicalBodyRegion] ↔ `clinical_data` stabil string.
abstract final class ClinicalBodyRegionMapping {
  static String toDb(ClinicalBodyRegion region) {
    switch (region) {
      case ClinicalBodyRegion.diz:
        return 'knee';
      case ClinicalBodyRegion.omuz:
        return 'shoulder';
      case ClinicalBodyRegion.kalca:
        return 'hip';
      case ClinicalBodyRegion.ayakBilegi:
        return 'ankle';
      case ClinicalBodyRegion.ayak:
        return 'foot';
      case ClinicalBodyRegion.dirsek:
        return 'elbow';
      case ClinicalBodyRegion.elBilegi:
        return 'wrist';
      case ClinicalBodyRegion.el:
        return 'hand';
      case ClinicalBodyRegion.omurga:
        return 'spine';
      case ClinicalBodyRegion.genel:
        return 'general';
      case ClinicalBodyRegion.diger:
        return 'other';
    }
  }

  static ClinicalBodyRegion fromDb(String? value) {
    switch (value?.trim()) {
      case 'knee':
        return ClinicalBodyRegion.diz;
      case 'shoulder':
        return ClinicalBodyRegion.omuz;
      case 'hip':
        return ClinicalBodyRegion.kalca;
      case 'ankle':
        return ClinicalBodyRegion.ayakBilegi;
      case 'foot':
        return ClinicalBodyRegion.ayak;
      case 'elbow':
        return ClinicalBodyRegion.dirsek;
      case 'wrist':
        return ClinicalBodyRegion.elBilegi;
      case 'hand':
        return ClinicalBodyRegion.el;
      case 'spine':
        return ClinicalBodyRegion.omurga;
      case 'general':
        return ClinicalBodyRegion.genel;
      case 'other':
        return ClinicalBodyRegion.diger;
      default:
        return ClinicalBodyRegion.genel;
    }
  }
}
