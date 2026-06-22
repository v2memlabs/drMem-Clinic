import '../models/clinical_report.dart';

abstract final class ClinicalReportUcabilirBodyTemplate {
  static const String flightConditionsHeading =
      'Uçuş için sağlaması gereken şart/koşullar:';

  static String compose({
    required String diagnosis,
    required ClinicalReportTreatmentApproach treatmentApproach,
    required ClinicalReportFlightDecision flightDecision,
    String? flightConditions,
  }) {
    final dx = diagnosis.trim().isEmpty ? '…' : diagnosis.trim();
    final treatment = treatmentApproachLabel(treatmentApproach);
    final decision = flightDecisionPhrase(flightDecision);

    final main =
        'Yukarıda kimliği belirtilen hastamız $dx tanısıyla $treatment '
        'tedaviyle takip edilmektedir. '
        'Yapılan klinik değerlendirme sonucunda hastanın $decision';

    if (flightDecision != ClinicalReportFlightDecision.kosullu) {
      return main;
    }

    final conditions = flightConditions?.trim() ?? '';
    if (conditions.isEmpty) return main;
    return '$main\n\n$flightConditionsHeading\n$conditions';
  }
}
