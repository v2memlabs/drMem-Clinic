import '../models/clinical_report.dart';
import 'clinical_report_number_helper.dart';
import 'mock_clinical_reports.dart';

class ClinicalReportRepository {
  ClinicalReportRepository._();

  static final ClinicalReportRepository instance = ClinicalReportRepository._();

  List<ClinicalReport> getAll() => List.unmodifiable(mockClinicalReports);

  ClinicalReport? getById(String id) {
    for (final item in mockClinicalReports) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<ClinicalReport> getByPatientId(String patientId) =>
      mockClinicalReports.where((r) => r.patientId == patientId).toList();

  List<ClinicalReport> getFiltered({
    String? patientId,
    String? query,
    ClinicalReportType? typeFilter,
    ClinicalReportStatus? statusFilter,
  }) {
    var list = patientId != null && patientId.isNotEmpty
        ? getByPatientId(patientId)
        : getAll();

    if (typeFilter != null) {
      list = list.where((r) => r.reportType == typeFilter).toList();
    }
    if (statusFilter != null) {
      list = list.where((r) => r.status == statusFilter).toList();
    }

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) => matchesQuery(r, q)).toList();
    }

    return list;
  }

  static bool matchesQuery(ClinicalReport r, String q) {
    final protocol = r.displayProtocolNumber?.toLowerCase() ?? '';
    if (protocol.isNotEmpty && protocol.contains(q)) return true;
    final reportNo = r.displayReportNumber?.toLowerCase() ?? '';
    if (reportNo.isNotEmpty && reportNo.contains(q)) return true;
    if (r.patientName.toLowerCase().contains(q)) return true;
    if (r.diagnosis.toLowerCase().contains(q)) return true;
    if (r.bodyText.toLowerCase().contains(q)) return true;
    if (clinicalReportTypeLabel(r.reportType).toLowerCase().contains(q)) {
      return true;
    }
    return false;
  }

  void add(ClinicalReport report) =>
      mockClinicalReports.insert(0, _ensureReportNumber(report));

  void update(ClinicalReport report) {
    final index = mockClinicalReports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      mockClinicalReports[index] = _ensureReportNumber(report);
    }
  }

  ClinicalReport _ensureReportNumber(ClinicalReport report) {
    if (report.displayReportNumber != null) return report;
    return report.copyWith(
      reportNumber: ClinicalReportNumberHelper.nextFromExisting(
        mockClinicalReports.map((r) => r.reportNumber ?? ''),
      ),
    );
  }
}
