import '../models/exercise_plan.dart';
import 'async_exercise_plan_repository_contract.dart';
import 'exercise_plan_repository_failure.dart';

class SupabaseAsyncExercisePlanRepositoryStub
    implements AsyncExercisePlanRepositoryContract {
  const SupabaseAsyncExercisePlanRepositoryStub();

  static const _error = ExercisePlanRepositoryException(
    ExercisePlanRepositoryFailure.notConfigured,
  );

  @override
  Future<ExercisePlan> create(ExercisePlan plan) async => throw _error;

  @override
  Future<List<ExercisePlan>> getAll() async => throw _error;

  @override
  Future<ExercisePlan?> getById(String id) async => throw _error;

  @override
  Future<List<ExercisePlan>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<ExercisePlan>> getByReferralId(String referralId) async =>
      throw _error;

  @override
  Future<List<ExercisePlan>> getFiltered({
    String? patientId,
    String? query,
    ExercisePlanPhase? phaseEnumFilter,
    ExercisePlanStatus? statusEnumFilter,
    bool? approvedByDoctor,
  }) async =>
      throw _error;

  @override
  Future<List<ExercisePlan>> search(String query) async => throw _error;

  @override
  Future<ExercisePlan> approveByDoctor(String id) async => throw _error;
}
