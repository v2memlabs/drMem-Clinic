import '../../../shared/widgets/info_section_card.dart';
import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_display.dart';

/// Hasta detayı asistan klinik özet kartı — allowlist alanlar.
abstract final class AssistantClinicalSummaryPatientDetailDisplay {
  static List<InfoSectionRow> cardRows(AssistantClinicalSummary summary) {
    final rows = <InfoSectionRow>[
      InfoSectionRow(
        'Son muayene',
        AssistantClinicalSummaryDisplay.formatDate(summary.encounterDate),
        emphasize: true,
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
      rows.add(InfoSectionRow('Kontrol tarihi', nextControl));
    }

    rows.add(
      InfoSectionRow(
        'Durum',
        AssistantClinicalSummaryDisplay.statusLabel(summary.status),
      ),
    );

    return rows;
  }
}
