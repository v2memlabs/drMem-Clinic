import '../models/exercise_plan.dart';
import 'exercise_plan_list_refresh.dart';
import 'exercise_plan_repository_failure.dart';
import 'exercise_plan_repository_provider.dart';
import 'exercise_plan_user_messages.dart';

abstract final class ExercisePlanFormDataSource {
  static Future<ExercisePlan> create(ExercisePlan draft) async {
    try {
      final saved = await ExercisePlanRepositoryProvider.asyncRepository.create(
        draft,
      );
      ExercisePlanListRefresh.markStale();
      return saved;
    } on ExercisePlanRepositoryException catch (e) {
      throw ExercisePlanFormException(
        ExercisePlanUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const ExercisePlanFormException(
        ExercisePlanUserMessages.genericSaveFailure,
      );
    }
  }
}

class ExercisePlanFormException implements Exception {
  final String message;

  const ExercisePlanFormException(this.message);

  @override
  String toString() => message;
}
