import '../models/exercise_plan.dart';
import 'exercise_plan_repository_failure.dart';
import 'exercise_plan_repository_provider.dart';
import 'exercise_plan_user_messages.dart';

class ExercisePlanListLoadResult {
  final List<ExercisePlan> plans;
  final String? errorMessage;

  const ExercisePlanListLoadResult._({
    this.plans = const [],
    this.errorMessage,
  });

  factory ExercisePlanListLoadResult.success(List<ExercisePlan> plans) {
    return ExercisePlanListLoadResult._(plans: plans);
  }

  factory ExercisePlanListLoadResult.failure(String message) {
    return ExercisePlanListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class ExercisePlanListDataSource {
  static Future<ExercisePlanListLoadResult> load({
    String? patientId,
    String? query,
    ExercisePlanPhase? phaseFilter,
    ExercisePlanStatus? statusFilter,
    bool? approvedByDoctor,
  }) async {
    try {
      final plans =
          await ExercisePlanRepositoryProvider.asyncRepository.getFiltered(
        patientId: patientId,
        query: query,
        phaseEnumFilter: phaseFilter,
        statusEnumFilter: statusFilter,
        approvedByDoctor: approvedByDoctor,
      );
      return ExercisePlanListLoadResult.success(plans);
    } on ExercisePlanRepositoryException catch (e) {
      return ExercisePlanListLoadResult.failure(
        ExercisePlanUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ExercisePlanListLoadResult.failure(
        ExercisePlanUserMessages.genericLoadFailure,
      );
    }
  }
}
