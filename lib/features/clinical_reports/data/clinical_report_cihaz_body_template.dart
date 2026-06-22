import '../models/clinical_report.dart';

abstract final class ClinicalReportCihazBodyTemplate {
  static const String usageInstructionHeading = 'Kullanım talimatı:';

  static String compose({
    required String diagnosis,
    required ClinicalReportTreatmentApproach treatmentApproach,
    required String deviceUsageDuration,
    required String deviceName,
    required String deviceUsageNotes,
    ClinicalReportWeightBearing? weightBearing,
    String? supplementaryNotes,
  }) {
    final dx = diagnosis.trim().isEmpty ? '…' : diagnosis.trim();
    final treatment = treatmentApproachLabel(treatmentApproach);
    final duration = deviceUsageDuration.trim().isEmpty
        ? '…'
        : deviceUsageDuration.trim();
    final device = deviceName.trim().isEmpty ? '…' : deviceName.trim();

    final main =
        'Yukarıda kimliği belirtilen hastamız $dx tanısıyla $treatment '
        'tedaviyle takip edilmektedir. '
        'Klinik değerlendirme sonucunda hastaya $duration süreyle '
        '$device kullanımı önerilmiştir.';

    final usageParts = <String>[];
    final usage = deviceUsageNotes.trim();
    if (usage.isNotEmpty) usageParts.add(usage);
    if (weightBearing != null) {
      usageParts.add(weightBearingFormLabel(weightBearing));
    }
    final usageLine = usageParts.join(' · ');

    final parts = <String>[main];
    if (usageLine.isNotEmpty) {
      parts.add('$usageInstructionHeading\n$usageLine');
    }

    final extra = supplementaryNotes?.trim() ?? '';
    if (extra.isNotEmpty) parts.add(extra);
    return parts.join('\n\n');
  }
}
