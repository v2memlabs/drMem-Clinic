import '../models/clinical_encounter.dart';
import 'clinical_encounter_summary_builder.dart';

/// Muayene listesi kartı — meta/context satırları (remote fallback uyumlu).
///
/// [internalDoctorNote] listede asla gösterilmez.
abstract final class ClinicalEncounterListDisplay {
  static String subtitleLine(ClinicalEncounter encounter) {
    final visit =
        '${encounter.visitType.label} • ${encounter.bodyRegion.label} / ${encounter.side.label}';
    if (!encounter.hasProtocolNumber) return visit;
    return '${encounter.displayProtocolNumber} • $visit';
  }

  static String formatEncounterDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  /// Liste alt satırı — ziyaret tipi + tanı (protokol no yok).
  static String listDetailLine(
    ClinicalEncounter encounter, {
    required bool usesRemote,
  }) {
    final visit = encounter.visitType.label;
    final diagnosis = cardMetaLine(encounter, usesRemote: usesRemote);
    if (diagnosis == null || diagnosis.isEmpty) return visit;
    return '$visit · $diagnosis';
  }

  /// Tanı özeti — boşsa null (gereksiz satır yok).
  static String? cardMetaLine(
    ClinicalEncounter encounter, {
    required bool usesRemote,
  }) {
    final finalDx = encounter.finalDiagnosis.trim();
    if (finalDx.isNotEmpty) return 'Kesin tanı: $finalDx';
    final prelim = encounter.preliminaryDiagnosis.trim();
    if (prelim.isNotEmpty) return 'Ön tanı: $prelim';

    if (usesRemote) {
      final summary =
          ClinicalEncounterSummaryBuilder.diagnosisSummary(encounter);
      if (summary != null && summary.trim().isNotEmpty) {
        return summary.trim();
      }
      return null;
    }

    return 'Tanı belirtilmedi';
  }

  /// ICD satırı — kod yoksa null.
  static String? cardContextLine(ClinicalEncounter encounter) {
    if (encounter.icdCode.trim().isEmpty) return null;
    final label = encounter.icdDisplay == '-'
        ? encounter.icdCode.trim()
        : encounter.icdDisplay.trim();
    return 'ICD: $label';
  }

  /// Kısa tedavi özeti — yalnızca anlamlı içerik varsa.
  static String? treatmentContextLine(ClinicalEncounter encounter) {
    final built =
        ClinicalEncounterSummaryBuilder.treatmentPlanSummary(encounter);
    if (built != null && built.trim().isNotEmpty) {
      return built.trim();
    }
    final summary = encounter.treatmentPlanSummary.trim();
    if (summary.isEmpty || summary == '-') return null;
    return summary;
  }
}
