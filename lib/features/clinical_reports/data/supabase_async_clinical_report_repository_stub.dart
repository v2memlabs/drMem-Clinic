import '../models/clinical_report.dart';
import 'async_clinical_report_repository_contract.dart';
import 'clinical_report_repository_failure.dart';

class SupabaseAsyncClinicalReportRepositoryStub
    implements AsyncClinicalReportRepositoryContract {
  const SupabaseAsyncClinicalReportRepositoryStub();

  static const _error = ClinicalReportRepositoryException(
    ClinicalReportRepositoryFailure.notConfigured,
  );

  @override
  Future<ClinicalReport> create(ClinicalReport report) async => throw _error;

  @override
  Future<List<ClinicalReport>> getAll() async => throw _error;

  @override
  Future<ClinicalReport?> getById(String id) async => throw _error;

  @override
  Future<List<ClinicalReport>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<ClinicalReport>> getFiltered({
    String? patientId,
    String? query,
    ClinicalReportType? typeFilter,
    ClinicalReportStatus? statusFilter,
  }) async =>
      throw _error;

  @override
  Future<ClinicalReport> update(ClinicalReport report) async => throw _error;
}
