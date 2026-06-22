import '../models/exercise_plan.dart';
import 'async_exercise_plan_repository_contract.dart';
import 'exercise_plan_repository.dart';

class MockAsyncExercisePlanRepositoryAdapter
    implements AsyncExercisePlanRepositoryContract {
  ExercisePlanRepository get _sync => ExercisePlanRepository.instance;

  @override
  Future<ExercisePlan> create(ExercisePlan plan) async {
    _sync.add(plan);
    return plan;
  }

  @override
  Future<List<ExercisePlan>> getAll() async => _sync.getAll();

  @override
  Future<ExercisePlan?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<ExercisePlan>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<ExercisePlan>> getByReferralId(String referralId) async =>
      _sync.getByReferralId(referralId);

  @override
  Future<List<ExercisePlan>> getFiltered({
    String? patientId,
    String? query,
    ExercisePlanPhase? phaseEnumFilter,
    ExercisePlanStatus? statusEnumFilter,
    bool? approvedByDoctor,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      query: query,
      phaseEnumFilter: phaseEnumFilter,
      statusEnumFilter: statusEnumFilter,
      approvedByDoctor: approvedByDoctor,
    );
  }

  @override
  Future<List<ExercisePlan>> search(String query) async => _sync.search(query);

  @override
  Future<ExercisePlan> approveByDoctor(String id) async =>
      _sync.approveByDoctor(id);
}
