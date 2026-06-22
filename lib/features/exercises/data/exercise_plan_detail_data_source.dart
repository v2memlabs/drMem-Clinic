import '../models/exercise_plan.dart';
import 'exercise_plan_repository_failure.dart';
import 'exercise_plan_repository_provider.dart';
import 'exercise_plan_user_messages.dart';

class ExercisePlanDetailLoadResult {
  final ExercisePlan? plan;
  final String? errorMessage;

  const ExercisePlanDetailLoadResult._({this.plan, this.errorMessage});

  factory ExercisePlanDetailLoadResult.success(ExercisePlan plan) {
    return ExercisePlanDetailLoadResult._(plan: plan);
  }

  factory ExercisePlanDetailLoadResult.failure(String message) {
    return ExercisePlanDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class ExercisePlanDetailDataSource {
  static Future<ExercisePlanDetailLoadResult> load(String id) async {
    try {
      final plan =
          await ExercisePlanRepositoryProvider.asyncRepository.getById(id);
      if (plan == null) {
        return ExercisePlanDetailLoadResult.failure(
            ExercisePlanUserMessages.notFound);
      }
      return ExercisePlanDetailLoadResult.success(plan);
    } on ExercisePlanRepositoryException catch (e) {
      return ExercisePlanDetailLoadResult.failure(
        ExercisePlanUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ExercisePlanDetailLoadResult.failure(
        ExercisePlanUserMessages.genericLoadFailure,
      );
    }
  }
}
