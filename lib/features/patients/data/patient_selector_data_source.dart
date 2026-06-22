import '../../../core/data/repository_registry.dart';
import '../models/patient.dart';
import 'patient_list_data_source.dart';
import 'patient_list_load_result.dart';
import 'patient_repository_failure.dart';

/// Hasta seçici — [RepositoryRegistry.patientsAsync] list/search/getById.
abstract final class PatientSelectorDataSource {
  static Future<PatientListLoadResult> loadPatients(String query) =>
      PatientListDataSource.load(query);

  static Future<Patient?> getById(String id) async {
    try {
      return await RepositoryRegistry.patientsAsync.getById(id);
    } on PatientRepositoryException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
