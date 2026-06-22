import '../models/clinical_report.dart';

abstract final class ClinicalReportDurumBildirirBodyTemplate {
  static const String legalNotice =
      'Durum bildirir uzman hekim raporudur.';

  static String compose({
    required String diagnosis,
    required ClinicalReportTreatmentApproach treatmentApproach,
    required String duration,
    required String recommendation,
    required ClinicalReportStatusSuitability suitability,
    String? supplementaryNotes,
  }) {
    final dx = diagnosis.trim().isEmpty ? '…' : diagnosis.trim();
    final treatment = treatmentApproachLabel(treatmentApproach);
    final dur = duration.trim().isEmpty ? '…' : duration.trim();
    final rec =
        recommendation.trim().isEmpty ? '…' : recommendation.trim();
    final suit = statusSuitabilityPhrase(suitability);

    final main =
        'Yukarıda kimliği belirtilen hastamız $dx tanısıyla $treatment '
        'tedaviyle takip edilmektedir. '
        'Hastanın $dur süreyle $rec $suit.';

    final parts = <String>[main, legalNotice];
    final extra = supplementaryNotes?.trim() ?? '';
    if (extra.isNotEmpty) parts.add(extra);
    return parts.join('\n\n');
  }
}
