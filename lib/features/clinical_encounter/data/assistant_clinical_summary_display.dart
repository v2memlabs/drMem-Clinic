import '../models/assistant_clinical_summary.dart';
import 'clinical_encounter_status_mapping.dart';
import 'clinical_visit_type_mapping.dart';

/// Assistant güvenli özet — UI etiket/format (allowlist).
abstract final class AssistantClinicalSummaryDisplay {
  static String visitTypeLabel(String? visitType) {
    return ClinicalVisitTypeMapping.fromDb(visitType).label;
  }

  static String statusLabel(String? status) {
    return ClinicalEncounterStatusMapping.fromDb(status).label;
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String? formatOptionalDate(DateTime? date) {
    if (date == null) return null;
    return formatDate(date);
  }

  static String listSubtitle(AssistantClinicalSummary summary) {
    final headline = summary.operationalHeadline?.trim() ?? '';
    if (headline.isNotEmpty) return headline;
    final dx = summary.diagnosisSummary?.trim() ?? '';
    if (dx.isNotEmpty) return dx;
    return 'Tanı özeti belirtilmedi';
  }

  static String? listMetaLine(AssistantClinicalSummary summary) {
    final visit = visitTypeLabel(summary.visitType);
    final status = statusLabel(summary.status);
    return '$visit • $status';
  }

  static List<String> listChips(AssistantClinicalSummary summary) {
    final chips = <String>[statusLabel(summary.status)];
    if (summary.hasPhysiotherapyReferral) {
      chips.add('FTR yönlendirme');
    }
    return chips;
  }
}
