import '../models/clinical_encounter.dart';
import 'clinical_encounter_list_display.dart';
import 'clinical_encounter_summary_builder.dart';

/// Hasta detayı gömülü muayene satırı — ziyaret özeti (hasta adı yok).
abstract final class ClinicalEncounterPatientScopedDisplay {
  static const _months = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String titleLine(ClinicalEncounter encounter) {
    final date = _formatDateLong(encounter.createdAt);
    if (encounter.hasProtocolNumber) {
      return '${encounter.displayProtocolNumber} · ${encounter.visitType.label} · $date';
    }
    return '${encounter.visitType.label} · $date';
  }

  static String? diagnosisSubtitle(ClinicalEncounter encounter) {
    final finalDx = encounter.finalDiagnosis.trim();
    if (finalDx.isNotEmpty) return 'Tanı: $finalDx';
    final prelim = encounter.preliminaryDiagnosis.trim();
    if (prelim.isNotEmpty) return 'Ön tanı: $prelim';
    return null;
  }

  static List<String> metaLines(
    ClinicalEncounter encounter, {
    required bool usesRemote,
  }) {
    final lines = <String>[];

    final plan = ClinicalEncounterListDisplay.treatmentContextLine(encounter);
    if (plan != null && plan.trim().isNotEmpty) {
      lines.add(plan.trim());
    }

    if (lines.length < 2) {
      final secondary = _secondaryMeta(encounter, usesRemote: usesRemote);
      if (secondary != null) lines.add(secondary);
    }

    return lines.take(2).toList();
  }

  static String? _secondaryMeta(
    ClinicalEncounter encounter, {
    required bool usesRemote,
  }) {
    final parts = <String>[];
    final doctor = encounter.doctorName.trim();
    if (doctor.isNotEmpty) parts.add(doctor);

    final icd = ClinicalEncounterListDisplay.cardContextLine(encounter);
    if (icd != null) {
      parts.add(icd);
    } else {
      parts.add(
        '${encounter.bodyRegion.label} / ${encounter.side.label}',
      );
    }

    if (parts.isEmpty) {
      if (usesRemote) {
        final summary =
            ClinicalEncounterSummaryBuilder.diagnosisSummary(encounter);
        if (summary != null && summary.trim().isNotEmpty) {
          return summary.trim();
        }
      }
      return null;
    }

    return parts.join(' · ');
  }

  static String statusTrailing(ClinicalEncounter encounter) {
    return encounter.status.label;
  }

  static String _formatDateLong(DateTime date) {
    final local = date.toLocal();
    final month = _months[local.month - 1];
    return '${local.day} $month ${local.year}';
  }
}
