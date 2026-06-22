import '../models/exercise_item.dart';
import '../models/exercise_plan.dart';
import 'exercise_plan_repository_failure.dart';

abstract final class ExercisePlanRemoteMapper {
  static const String table = 'exercise_plans';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, referral_id, title, diagnosis_summary, '
      'phase, goal, exercises, home_instructions, warnings, doctor_approved, '
      'control_date, status, notes, created_by, created_by_display, created_at, '
      'patients(first_name, last_name)';

  static ExercisePlan fromRow(Map<String, dynamic> row) {
    final patientName = _embeddedPatientFullName(row['patients']) ?? 'Hasta';
    final createdAt = _requireDateTime(row['created_at']);
    final controlDate = _optionalDate(row['control_date']);

    return ExercisePlan(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: patientName,
      title: _optionalString(row['title']) ?? 'Egzersiz Programı',
      createdBy: _optionalString(row['created_by_display']) ?? '',
      createdAt: createdAt,
      diagnosisSummary: _optionalString(row['diagnosis_summary']) ?? '-',
      phase: _enumFromDb(ExercisePlanPhase.values, row['phase']),
      goal: _optionalString(row['goal']) ?? '-',
      exercises: _exerciseItemsFromJson(row['exercises']),
      homeInstructions: _optionalString(row['home_instructions']) ?? '',
      warnings: _optionalString(row['warnings']) ?? '',
      doctorApproved: row['doctor_approved'] == true,
      controlDate: controlDate,
      status: _enumFromDb(ExercisePlanStatus.values, row['status']),
      notes: _optionalString(row['notes']) ?? '',
      referralId: _optionalString(row['referral_id']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required ExercisePlan plan,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': plan.patientId.trim(),
      if (plan.referralId?.trim().isNotEmpty == true)
        'referral_id': plan.referralId!.trim(),
      'title': plan.title.trim(),
      'diagnosis_summary': plan.diagnosisSummary.trim(),
      'phase': plan.phase.name,
      'goal': plan.goal.trim(),
      'exercises': plan.exercises.map(_exerciseItemToJson).toList(),
      'home_instructions': plan.homeInstructions.trim(),
      'warnings': plan.warnings.trim(),
      'doctor_approved': plan.doctorApproved,
      if (plan.controlDate != null)
        'control_date': _dateOnly(plan.controlDate!),
      'status': plan.status.name,
      'notes': plan.notes.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : plan.createdBy.trim(),
    };
  }

  static Map<String, dynamic> _exerciseItemToJson(ExerciseItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'repetitions': item.repetitions,
      'sets': item.sets,
      'duration': item.duration,
      'frequency': item.frequency,
      'precautions': item.precautions,
      'notes': item.notes,
    };
  }

  static List<ExerciseItem> _exerciseItemsFromJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.invalidRow,
      );
    }
    return raw.map((item) {
      if (item is! Map) {
        throw const ExercisePlanRepositoryException(
          ExercisePlanRepositoryFailure.invalidRow,
        );
      }
      return ExerciseItem(
        id: _optionalString(item['id']) ?? '',
        name: _optionalString(item['name']) ?? '',
        description: _optionalString(item['description']) ?? '',
        repetitions: _optionalInt(item['repetitions']) ?? 10,
        sets: _optionalInt(item['sets']) ?? 3,
        duration: _optionalString(item['duration']) ?? '',
        frequency: _optionalString(item['frequency']) ?? '',
        precautions: _optionalString(item['precautions']) ?? '',
        notes: _optionalString(item['notes']) ?? '',
      );
    }).toList();
  }

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.invalidRow,
      );
    }
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static int? _optionalInt(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  static DateTime _requireDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static DateTime? _optionalDate(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _embeddedPatientFullName(dynamic value) {
    if (value is Map) {
      final first = value['first_name']?.toString().trim() ?? '';
      final last = value['last_name']?.toString().trim() ?? '';
      final name = '$first $last'.trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  static T _enumFromDb<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const ExercisePlanRepositoryException(
      ExercisePlanRepositoryFailure.invalidRow,
    );
  }
}
