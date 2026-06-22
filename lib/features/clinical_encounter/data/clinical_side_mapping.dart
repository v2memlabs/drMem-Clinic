import '../models/clinical_encounter.dart';

/// [ClinicalSide] ↔ `clinical_data` stabil string.
abstract final class ClinicalSideMapping {
  static String toDb(ClinicalSide side) {
    switch (side) {
      case ClinicalSide.sag:
        return 'right';
      case ClinicalSide.sol:
        return 'left';
      case ClinicalSide.bilateral:
        return 'bilateral';
      case ClinicalSide.uygunDegil:
        return 'not_applicable';
    }
  }

  static ClinicalSide fromDb(String? value) {
    switch (value?.trim()) {
      case 'right':
        return ClinicalSide.sag;
      case 'left':
        return ClinicalSide.sol;
      case 'bilateral':
        return ClinicalSide.bilateral;
      case 'not_applicable':
        return ClinicalSide.uygunDegil;
      default:
        return ClinicalSide.uygunDegil;
    }
  }
}
