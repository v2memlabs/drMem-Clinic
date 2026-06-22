import '../../../core/data/repository_registry.dart';
import 'patient_count_load_result.dart';
import 'patient_count_user_messages.dart';
import 'patient_repository_failure.dart';

/// Demo/ayarlar hasta kaydı sayısı — [RepositoryRegistry.patientsAsync].count().
abstract final class PatientCountDataSource {
  static Future<PatientCountLoadResult> load() async {
    try {
      final count = await RepositoryRegistry.patientsAsync.count();
      return PatientCountLoadResult.success(count);
    } on PatientRepositoryException catch (e) {
      return PatientCountLoadResult.failure(
        PatientCountUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PatientCountLoadResult.failure(
        PatientCountUserMessages.genericFailure,
      );
    }
  }
}
