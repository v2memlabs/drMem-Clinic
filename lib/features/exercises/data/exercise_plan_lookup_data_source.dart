import '../../../core/data/repository_registry.dart';
import '../models/exercise_plan.dart';

/// Egzersiz programı okuma — [RepositoryRegistry.exercisePlansAsync].
abstract final class ExercisePlanLookupDataSource {
  static Future<ExercisePlan?> findById(String planId) async {
    final id = planId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.exercisePlansAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<ExercisePlan>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.exercisePlansAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
