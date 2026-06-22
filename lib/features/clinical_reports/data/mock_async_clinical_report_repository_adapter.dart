import '../models/clinical_report.dart';
import 'async_clinical_report_repository_contract.dart';
import 'clinical_report_repository.dart';

class MockAsyncClinicalReportRepositoryAdapter
    implements AsyncClinicalReportRepositoryContract {
  ClinicalReportRepository get _sync => ClinicalReportRepository.instance;

  @override
  Future<ClinicalReport> create(ClinicalReport report) async {
    _sync.add(report);
    return _sync.getById(report.id) ?? report;
  }

  @override
  Future<List<ClinicalReport>> getAll() async => _sync.getAll();

  @override
  Future<ClinicalReport?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<ClinicalReport>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<ClinicalReport>> getFiltered({
    String? patientId,
    String? query,
    ClinicalReportType? typeFilter,
    ClinicalReportStatus? statusFilter,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      query: query,
      typeFilter: typeFilter,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<ClinicalReport> update(ClinicalReport report) async {
    _sync.update(report);
    return _sync.getById(report.id) ?? report;
  }
}
