import '../models/exercise_plan.dart';
import 'mock_exercise_plans.dart';

class ExercisePlanRepository {
  ExercisePlanRepository._();

  static final ExercisePlanRepository instance = ExercisePlanRepository._();

  List<ExercisePlan> getAll() => List.unmodifiable(mockExercisePlans);

  ExercisePlan? getById(String id) {
    for (final plan in mockExercisePlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  List<ExercisePlan> getByPatientId(String patientId) =>
      mockExercisePlans.where((p) => p.patientId == patientId).toList();

  List<ExercisePlan> getByReferralId(String referralId) {
    final list =
        mockExercisePlans.where((p) => p.referralId == referralId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<ExercisePlan> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockExercisePlans.where((p) => matchesQuery(p, q)).toList();
  }

  List<ExercisePlan> getFiltered({
    String? patientId,
    String? query,
    String? phaseFilter,
    ExercisePlanPhase? phaseEnumFilter,
    String? statusFilter,
    ExercisePlanStatus? statusEnumFilter,
    bool? approvedByDoctor,
  }) {
    Iterable<ExercisePlan> list = mockExercisePlans;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((p) => p.patientId == patientId);
    }
    if (phaseEnumFilter != null) {
      list = list.where((p) => p.phase == phaseEnumFilter);
    } else if (phaseFilter != null && phaseFilter.isNotEmpty) {
      final pf = phaseFilter.toLowerCase();
      list = list.where(
          (p) => exercisePlanPhaseLabel(p.phase).toLowerCase().contains(pf));
    }
    if (statusEnumFilter != null) {
      list = list.where((p) => p.status == statusEnumFilter);
    } else if (statusFilter != null && statusFilter.isNotEmpty) {
      final sf = statusFilter.toLowerCase();
      list = list.where(
          (p) => exercisePlanStatusLabel(p.status).toLowerCase().contains(sf));
    }
    if (approvedByDoctor != null) {
      list = list.where((p) => p.doctorApproved == approvedByDoctor);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((p) => matchesQuery(p, q));
    }

    return List<ExercisePlan>.from(list);
  }

  void add(ExercisePlan plan) => mockExercisePlans.insert(0, plan);

  ExercisePlan approveByDoctor(String id) {
    final index = mockExercisePlans.indexWhere((p) => p.id == id);
    if (index < 0) {
      throw StateError('Plan not found');
    }
    final current = mockExercisePlans[index];
    final approved = ExercisePlan(
      id: current.id,
      patientId: current.patientId,
      patientName: current.patientName,
      title: current.title,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      diagnosisSummary: current.diagnosisSummary,
      phase: current.phase,
      goal: current.goal,
      exercises: current.exercises,
      homeInstructions: current.homeInstructions,
      warnings: current.warnings,
      doctorApproved: true,
      controlDate: current.controlDate,
      status: ExercisePlanStatus.aktif,
      notes: current.notes,
      referralId: current.referralId,
    );
    mockExercisePlans[index] = approved;
    return approved;
  }

  static bool matchesQuery(ExercisePlan p, String q) {
    if (p.patientName.toLowerCase().contains(q)) return true;
    if (p.title.toLowerCase().contains(q)) return true;
    if (p.diagnosisSummary.toLowerCase().contains(q)) return true;
    if (p.goal.toLowerCase().contains(q)) return true;
    if (exercisePlanPhaseLabel(p.phase).toLowerCase().contains(q)) return true;
    if (exercisePlanStatusLabel(p.status).toLowerCase().contains(q)) {
      return true;
    }
    if (p.createdBy.toLowerCase().contains(q)) return true;
    if (p.notes.toLowerCase().contains(q)) return true;
    return false;
  }
}
