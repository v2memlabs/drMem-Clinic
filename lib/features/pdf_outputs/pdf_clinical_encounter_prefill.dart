import '../clinical_encounter/models/clinical_encounter.dart';

/// Muayene kaydından PDF meta özeti için güvenli özet (hassas alanlar hariç).
class PdfClinicalEncounterPrefill {
  PdfClinicalEncounterPrefill._();

  static const String unspecified = 'Belirtilmedi';

  static String diagnosisLine(ClinicalEncounter e) {
    final finalDx = e.finalDiagnosis.trim();
    if (finalDx.isNotEmpty) return finalDx;
    final prelim = e.preliminaryDiagnosis.trim();
    if (prelim.isNotEmpty) return prelim;
    return unspecified;
  }

  static String treatmentPlanLine(ClinicalEncounter e) {
    final conservative = e.conservativeTreatment.trim();
    if (conservative.isNotEmpty) return _truncate(conservative, 120);
    final title = e.planTitle.trim();
    if (title.isNotEmpty) return _truncate(title, 120);
    return unspecified;
  }

  static String contentSummary(ClinicalEncounter e) {
    final lines = <String>[
      'Başvuru tipi: ${e.visitType.label}',
      'Durum: ${e.status.label}',
      'Bölge / taraf: ${e.bodyRegion.label} / ${e.side.label}',
      'Tanı özeti: ${diagnosisLine(e)}',
    ];

    final impression = e.clinicalImpression.trim();
    if (impression.isNotEmpty) {
      lines.add('Klinik izlenim: ${_truncate(impression, 100)}');
    }

    final plan = treatmentPlanLine(e);
    if (plan != unspecified) {
      lines.add('Tedavi planı: $plan');
    }

    if (e.physiotherapyReferral) {
      lines.add('Fizyoterapi yönlendirmesi: Evet');
    }

    if (e.controlDate != null) {
      lines.add('Kontrol tarihi: ${_formatDate(e.controlDate!)}');
    }

    return lines.join('\n');
  }

  static String defaultTitle(String patientDisplayName) {
    final name = patientDisplayName.trim().isEmpty
        ? 'Hasta'
        : patientDisplayName.trim();
    return 'Muayene Özeti — $name';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  static String _truncate(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }
}
