import 'exercise_item.dart';

enum ExercisePlanPhase {
  erkenRehabilitasyon,
  ortaRehabilitasyon,
  ileriRehabilitasyon,
  sporaDonus,
  koruyucu,
}

enum ExercisePlanStatus {
  taslak,
  aktif,
  hastayaVerildi,
  doktorOnayBekliyor,
  tamamlandi,
  arsiv,
}

class ExercisePlan {
  final String id;
  final String patientId;
  final String patientName;
  final String title;
  final String createdBy;
  final DateTime createdAt;
  final String diagnosisSummary;
  final ExercisePlanPhase phase;
  final String goal;
  final List<ExerciseItem> exercises;
  final String homeInstructions;
  final String warnings;
  final bool doctorApproved;
  final DateTime? controlDate;
  final ExercisePlanStatus status;
  final String notes;
  final String? referralId;

  ExercisePlan({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    required this.diagnosisSummary,
    required this.phase,
    required this.goal,
    required this.exercises,
    this.homeInstructions = '',
    this.warnings = '',
    this.doctorApproved = false,
    this.controlDate,
    this.status = ExercisePlanStatus.taslak,
    this.notes = '',
    this.referralId,
  });
}

String exercisePlanPhaseLabel(ExercisePlanPhase phase) {
  switch (phase) {
    case ExercisePlanPhase.erkenRehabilitasyon:
      return 'Erken Rehabilitasyon';
    case ExercisePlanPhase.ortaRehabilitasyon:
      return 'Orta Rehabilitasyon';
    case ExercisePlanPhase.ileriRehabilitasyon:
      return 'İleri Rehabilitasyon';
    case ExercisePlanPhase.sporaDonus:
      return 'Spora Dönüş';
    case ExercisePlanPhase.koruyucu:
      return 'Koruyucu';
  }
}

String exercisePlanStatusLabel(ExercisePlanStatus status) {
  switch (status) {
    case ExercisePlanStatus.taslak:
      return 'Taslak';
    case ExercisePlanStatus.aktif:
      return 'Aktif';
    case ExercisePlanStatus.hastayaVerildi:
      return 'Hastaya Verildi';
    case ExercisePlanStatus.doktorOnayBekliyor:
      return 'Doktor Onayı Bekliyor';
    case ExercisePlanStatus.tamamlandi:
      return 'Tamamlandı';
    case ExercisePlanStatus.arsiv:
      return 'Arşiv';
  }
}
