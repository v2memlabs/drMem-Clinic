import 'exercise_plan_repository_failure.dart';

abstract final class ExercisePlanRepositoryErrorMapper {
  static ExercisePlanRepositoryException toException(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission') ||
        msg.contains('rls') ||
        msg.contains('42501')) {
      return const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.forbidden,
      );
    }
    if (msg.contains('not found') || msg.contains('pgrst116')) {
      return const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.notFound,
      );
    }
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.network,
      );
    }
    if (msg.contains('supabase') && msg.contains('configured')) {
      return const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.notConfigured,
      );
    }
    return const ExercisePlanRepositoryException(
      ExercisePlanRepositoryFailure.unknown,
    );
  }
}
