import '../../../core/data/repository_registry.dart';
import 'exercise_plan_detail_data_source.dart';
import 'exercise_plan_repository_failure.dart';
import 'exercise_plan_user_messages.dart';

abstract final class ExercisePlanApprovalDataSource {
  static Future<ExercisePlanDetailLoadResult> approve(String id) async {
    try {
      final plan =
          await RepositoryRegistry.exercisePlansAsync.approveByDoctor(id);
      return ExercisePlanDetailLoadResult.success(plan);
    } on ExercisePlanRepositoryException catch (e) {
      return ExercisePlanDetailLoadResult.failure(
        ExercisePlanUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ExercisePlanDetailLoadResult.failure(
        'Rehabilitasyon planı onaylanamadı.',
      );
    }
  }
}
