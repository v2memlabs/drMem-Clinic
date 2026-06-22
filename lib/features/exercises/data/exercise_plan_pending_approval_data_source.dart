import '../../../core/data/repository_registry.dart';
import '../models/exercise_plan.dart';

/// Doktor onayı bekleyen rehabilitasyon planları.
abstract final class ExercisePlanPendingApprovalDataSource {
  static Future<int> countPending() async {
    final list = await RepositoryRegistry.exercisePlansAsync.getFiltered(
      statusEnumFilter: ExercisePlanStatus.doktorOnayBekliyor,
      approvedByDoctor: false,
    );
    return list.length;
  }

  static Future<List<ExercisePlan>> listPending() async {
    return RepositoryRegistry.exercisePlansAsync.getFiltered(
      statusEnumFilter: ExercisePlanStatus.doktorOnayBekliyor,
      approvedByDoctor: false,
    );
  }
}
