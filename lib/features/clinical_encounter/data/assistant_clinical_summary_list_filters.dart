import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_display.dart';

/// Assistant özet listesi — istemci tarafı arama (allowlist alanlar).
abstract final class AssistantClinicalSummaryListFilters {
  static List<AssistantClinicalSummary> applySearch(
    List<AssistantClinicalSummary> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((s) {
      if (s.patientDisplayName.toLowerCase().contains(q)) return true;
      final dx = s.diagnosisSummary?.toLowerCase() ?? '';
      if (dx.contains(q)) return true;
      final headline = s.operationalHeadline?.toLowerCase() ?? '';
      if (headline.contains(q)) return true;
      final visit = AssistantClinicalSummaryDisplay.visitTypeLabel(s.visitType)
          .toLowerCase();
      if (visit.contains(q)) return true;
      final status =
          AssistantClinicalSummaryDisplay.statusLabel(s.status).toLowerCase();
      if (status.contains(q)) return true;
      return false;
    }).toList();
  }
}
