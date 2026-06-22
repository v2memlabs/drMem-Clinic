import '../../../core/data/repository_registry.dart';
import 'patient_detail_load_result.dart';
import 'patient_detail_user_messages.dart';
import 'patient_repository_failure.dart';

/// Hasta detay — [RepositoryRegistry.patientsAsync].getById.
abstract final class PatientDetailDataSource {
  static Future<PatientDetailLoadResult> loadById(String id) async {
    try {
      final patient = await RepositoryRegistry.patientsAsync.getById(id);
      if (patient == null) {
        return PatientDetailLoadResult.notFound();
      }
      return PatientDetailLoadResult.success(patient);
    } on PatientRepositoryException catch (e) {
      if (e.reason == PatientRepositoryFailure.notFound) {
        return PatientDetailLoadResult.notFound();
      }
      return PatientDetailLoadResult.failure(
        PatientDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PatientDetailLoadResult.failure(
        PatientDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
