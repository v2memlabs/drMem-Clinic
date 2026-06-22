import '../models/clinical_report.dart';

abstract interface class AsyncClinicalReportRepositoryContract {
  Future<List<ClinicalReport>> getAll();

  Future<List<ClinicalReport>> getByPatientId(String patientId);

  Future<ClinicalReport?> getById(String id);

  Future<List<ClinicalReport>> getFiltered({
    String? patientId,
    String? query,
    ClinicalReportType? typeFilter,
    ClinicalReportStatus? statusFilter,
  });

  Future<ClinicalReport> create(ClinicalReport report);

  Future<ClinicalReport> update(ClinicalReport report);
}
