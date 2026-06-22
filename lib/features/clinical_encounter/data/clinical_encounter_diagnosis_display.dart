import '../../../shared/widgets/info_section_card.dart';
import '../models/clinical_encounter.dart';

/// Tanı bölümü — başlık, sıra ve kesin tanı kilidi.
abstract final class ClinicalEncounterDiagnosisDisplay {
  static const String sectionTitle = 'Ön tanı/Tanı';
  static const String summaryTitle = 'Ön tanı/Tanı özeti';

  static bool hasFinalDiagnosis(ClinicalEncounter e) =>
      e.finalDiagnosis.trim().isNotEmpty;

  static String displayIcd(ClinicalEncounter e) {
    if (e.icdCode.trim().isEmpty) return kDisplayUnspecified;
    return e.icdDisplay == '-' ? _display(e.icdCode) : e.icdDisplay;
  }

  static List<InfoSectionRow> detailRows(ClinicalEncounter e) {
    if (hasFinalDiagnosis(e)) {
      return [
        InfoSectionRow(
          'Kesin tanı',
          _display(e.finalDiagnosis),
          emphasize: true,
        ),
        InfoSectionRow('ICD-10 kodu', displayIcd(e)),
      ];
    }

    return [
      InfoSectionRow('Ön tanı', _display(e.preliminaryDiagnosis), emphasize: true),
      InfoSectionRow('Ayırıcı tanı', _display(e.differentialDiagnosis)),
      InfoSectionRow('Kesin tanı', _display(e.finalDiagnosis)),
      InfoSectionRow('Tanı tipi', e.diagnosisType.label),
      InfoSectionRow('ICD-10 kodu', displayIcd(e)),
    ];
  }

  /// PDF ve meta özet için etiket/değer çiftleri.
  static List<({String label, String value})> pdfRows(ClinicalEncounter e) {
    if (hasFinalDiagnosis(e)) {
      return [
        (label: 'Kesin tanı', value: _display(e.finalDiagnosis)),
        (label: 'ICD-10 kodu', value: displayIcd(e)),
      ];
    }

    return [
      (label: 'Ön tanı', value: _display(e.preliminaryDiagnosis)),
      (label: 'Ayırıcı tanı', value: _display(e.differentialDiagnosis)),
      (label: 'Kesin tanı', value: _display(e.finalDiagnosis)),
      (label: 'ICD-10 kodu', value: displayIcd(e)),
    ];
  }

  static String _display(String v) =>
      v.trim().isEmpty ? kDisplayUnspecified : v.trim();
}
