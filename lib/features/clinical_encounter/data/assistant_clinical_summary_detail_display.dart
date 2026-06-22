import '../../../shared/widgets/info_section_card.dart';
import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_display.dart';

/// Assistant özet detay satırları — allowlist alanlar.
abstract final class AssistantClinicalSummaryDetailDisplay {
  static String headerSubtitle(AssistantClinicalSummary summary) {
    final visit = AssistantClinicalSummaryDisplay.visitTypeLabel(summary.visitType);
    final status = AssistantClinicalSummaryDisplay.statusLabel(summary.status);
    return '$visit • $status';
  }

  static List<InfoSectionRow> detailRows(AssistantClinicalSummary summary) {
    final rows = <InfoSectionRow>[
      InfoSectionRow(
        'Muayene tarihi',
        AssistantClinicalSummaryDisplay.formatDate(summary.encounterDate),
        emphasize: true,
      ),
      InfoSectionRow(
        'Durum',
        AssistantClinicalSummaryDisplay.statusLabel(summary.status),
      ),
      InfoSectionRow(
        'Başvuru tipi',
        AssistantClinicalSummaryDisplay.visitTypeLabel(summary.visitType),
      ),
    ];

    final dx = summary.diagnosisSummary?.trim() ?? '';
    if (dx.isNotEmpty) {
      rows.add(InfoSectionRow('Tanı özeti', dx, emphasize: true));
    }

    final headline = summary.operationalHeadline?.trim() ?? '';
    if (headline.isNotEmpty) {
      rows.add(InfoSectionRow('Operasyonel başlık', headline));
    }

    final nextControl = AssistantClinicalSummaryDisplay.formatOptionalDate(
      summary.nextControlDate,
    );
    if (nextControl != null) {
      rows.add(InfoSectionRow('Sonraki kontrol', nextControl));
    }

    rows.add(
      InfoSectionRow(
        'FTR yönlendirme',
        summary.hasPhysiotherapyReferral ? 'Evet' : 'Hayır',
      ),
    );

    final updated = AssistantClinicalSummaryDisplay.formatOptionalDate(
      summary.updatedAt,
    );
    if (updated != null) {
      rows.add(InfoSectionRow('Son güncelleme', updated));
    }

    return rows;
  }
}
