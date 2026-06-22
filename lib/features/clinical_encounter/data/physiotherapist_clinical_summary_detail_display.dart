import '../../../shared/widgets/info_section_card.dart';
import '../models/physiotherapist_clinical_summary.dart';
import 'physiotherapist_clinical_summary_display.dart';

/// FTR özet detay satırları — allowlist alanlar.
abstract final class PhysiotherapistClinicalSummaryDetailDisplay {
  static String headerSubtitle(PhysiotherapistClinicalSummary summary) {
    final date =
        PhysiotherapistClinicalSummaryDisplay.formatDate(summary.encounterDate);
    final dx = summary.diagnosisSummary?.trim() ?? '';
    if (dx.isEmpty) return date;
    final shortDx = dx.length > 80 ? '${dx.substring(0, 80)}…' : dx;
    return '$date • $shortDx';
  }

  static List<InfoSectionRow> patientRows(PhysiotherapistClinicalSummary summary) {
    return [
      InfoSectionRow(
        'Hasta',
        summary.patientDisplayName,
        emphasize: true,
      ),
      InfoSectionRow(
        'Muayene tarihi',
        PhysiotherapistClinicalSummaryDisplay.formatDate(summary.encounterDate),
        emphasize: true,
      ),
      InfoSectionRow(
        'Bölge / taraf',
        '${PhysiotherapistClinicalSummaryDisplay.bodyRegionLabel(summary.bodyRegion)} / '
        '${PhysiotherapistClinicalSummaryDisplay.sideLabel(summary.side)}',
      ),
      InfoSectionRow(
        'Başvuru tipi',
        PhysiotherapistClinicalSummaryDisplay.visitTypeLabel(summary.visitType),
      ),
      InfoSectionRow(
        'Durum',
        PhysiotherapistClinicalSummaryDisplay.statusLabel(summary.status),
      ),
    ];
  }

  static List<InfoSectionRow> diagnosisRows(
    PhysiotherapistClinicalSummary summary,
  ) {
    final rows = <InfoSectionRow>[];
    final dx = PhysiotherapistClinicalSummaryDisplay.displayOptional(
      summary.diagnosisSummary,
    );
    if (dx != null) {
      rows.add(InfoSectionRow('Tanı özeti', dx, emphasize: true));
    }
    final plan = PhysiotherapistClinicalSummaryDisplay.displayOptional(
      summary.treatmentPlanSummary,
    );
    if (plan != null) {
      rows.add(InfoSectionRow('Tedavi planı özeti', plan));
    }
    return rows;
  }

  static List<InfoSectionRow> rehabRows(PhysiotherapistClinicalSummary summary) {
    final rows = <InfoSectionRow>[
      InfoSectionRow(
        'Fizyoterapi yönlendirmesi',
        summary.physiotherapyReferral ? 'Evet' : 'Hayır',
        emphasize: true,
      ),
    ];

    _addOptionalRow(rows, 'Egzersiz önerisi', summary.exerciseRecommendationShort);
    _addOptionalRow(rows, 'Rehab. önlemleri', summary.rehabPrecautionsShort);
    _addOptionalRow(rows, 'Yük verme durumu', summary.weightBearingStatus);
    _addOptionalRow(rows, 'Eklem hareketi özeti', summary.romLimitationShort);
    _addOptionalRow(rows, 'Post-op bağlam', summary.postOpContextShort);
    _addOptionalRow(rows, 'FTR hedefi', summary.ftrGoalShort);

    final control = PhysiotherapistClinicalSummaryDisplay.formatOptionalDate(
      summary.controlDate,
    );
    if (control != null) {
      rows.add(InfoSectionRow('Kontrol tarihi', control));
    }

    final updated = PhysiotherapistClinicalSummaryDisplay.formatOptionalDate(
      summary.updatedAt,
    );
    if (updated != null) {
      rows.add(InfoSectionRow('Son güncelleme', updated));
    }

    return rows;
  }

  static void _addOptionalRow(
    List<InfoSectionRow> rows,
    String label,
    String? value,
  ) {
    final display = PhysiotherapistClinicalSummaryDisplay.displayOptional(value);
    if (display != null) {
      rows.add(InfoSectionRow(label, display));
    }
  }
}
