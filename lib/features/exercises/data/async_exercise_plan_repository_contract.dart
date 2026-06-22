import '../models/exercise_plan.dart';

abstract interface class AsyncExercisePlanRepositoryContract {
  Future<List<ExercisePlan>> getAll();

  Future<List<ExercisePlan>> getByPatientId(String patientId);

  Future<List<ExercisePlan>> getByReferralId(String referralId);

  Future<ExercisePlan?> getById(String id);

  Future<List<ExercisePlan>> search(String query);

  Future<List<ExercisePlan>> getFiltered({
    String? patientId,
    String? query,
    ExercisePlanPhase? phaseEnumFilter,
    ExercisePlanStatus? statusEnumFilter,
    bool? approvedByDoctor,
  });

  Future<ExercisePlan> create(ExercisePlan plan);

  Future<ExercisePlan> approveByDoctor(String id);
}
