import '../../../core/data/repository_registry.dart';
import '../models/clinical_report.dart';

abstract final class ClinicalReportLookupDataSource {
  static Future<ClinicalReport?> findById(String reportId) async {
    final id = reportId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.clinicalReportsAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<ClinicalReport>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.clinicalReportsAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
