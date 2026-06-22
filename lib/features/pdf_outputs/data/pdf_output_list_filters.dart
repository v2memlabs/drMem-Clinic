import '../models/pdf_output.dart';

/// PDF çıktı listesi — arama ve filtre (mock/remote ortak).
abstract final class PdfOutputListFilters {
  static List<PdfOutput> apply({
    required List<PdfOutput> items,
    String? patientId,
    String? query,
    DocumentType? documentTypeFilter,
    PdfStatus? statusFilter,
  }) {
    Iterable<PdfOutput> list = items;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((p) => p.patientId == patientId);
    }
    if (documentTypeFilter != null) {
      list = list.where((p) => p.documentType == documentTypeFilter);
    }
    if (statusFilter != null) {
      list = list.where((p) => p.status == statusFilter);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((p) => _matchesQuery(p, q));
    }

    final result = List<PdfOutput>.from(list);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static bool _matchesQuery(PdfOutput p, String q) {
    if (p.patientName.toLowerCase().contains(q)) return true;
    if (p.title.toLowerCase().contains(q)) return true;
    if (documentTypeLabel(p.documentType).toLowerCase().contains(q)) return true;
    if (pdfStatusLabel(p.status).toLowerCase().contains(q)) return true;
    if (p.createdBy.toLowerCase().contains(q)) return true;
    if (p.contentSummary.toLowerCase().contains(q)) return true;
    if (p.warningNote.toLowerCase().contains(q)) return true;
    if ((p.relatedDiagnosis ?? '').toLowerCase().contains(q)) return true;
    if ((p.relatedTreatmentPlan ?? '').toLowerCase().contains(q)) return true;
    return false;
  }
}
