import '../models/pdf_output.dart';
import 'mock_pdf_outputs.dart';

class PdfOutputRepository {
  PdfOutputRepository._();

  static final PdfOutputRepository instance = PdfOutputRepository._();

  List<PdfOutput> getAll() => List.unmodifiable(mockPdfOutputs);

  PdfOutput? getById(String id) {
    for (final record in mockPdfOutputs) {
      if (record.id == id) return record;
    }
    return null;
  }

  List<PdfOutput> getByPatientId(String patientId) =>
      mockPdfOutputs.where((p) => p.patientId == patientId).toList();

  List<PdfOutput> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockPdfOutputs.where((p) => _matchesQuery(p, q)).toList();
  }

  List<PdfOutput> getFiltered({
    String? patientId,
    String? query,
    DocumentType? documentTypeFilter,
    PdfStatus? statusFilter,
  }) {
    Iterable<PdfOutput> list = mockPdfOutputs;

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

    return List<PdfOutput>.from(list);
  }

  void add(PdfOutput record) => mockPdfOutputs.insert(0, record);

  bool _matchesQuery(PdfOutput p, String q) {
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
