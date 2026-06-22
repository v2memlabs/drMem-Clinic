import '../models/physiotherapy_session_note.dart';

abstract final class PhysiotherapySessionListFilters {
  static bool matchesQuery(PhysiotherapySessionNote s, String lowerQuery) {
    if (s.patientName.toLowerCase().contains(lowerQuery)) return true;
    if (s.physiotherapistName.toLowerCase().contains(lowerQuery)) return true;
    if (s.returnToSportLabel.toLowerCase().contains(lowerQuery)) return true;
    if (s.notes.toLowerCase().contains(lowerQuery)) return true;
    if (s.exercisesPerformed.toLowerCase().contains(lowerQuery)) return true;
    if (s.functionalAssessment.toLowerCase().contains(lowerQuery)) return true;
    return false;
  }

  static List<PhysiotherapySessionNote> apply({
    required List<PhysiotherapySessionNote> items,
    String? query,
    ReturnToSportStage? returnToSportStageEnumFilter,
    bool? doctorNotificationNeeded,
  }) {
    Iterable<PhysiotherapySessionNote> list = items;

    if (returnToSportStageEnumFilter != null) {
      list = list.where((s) => s.returnToSportStage == returnToSportStageEnumFilter);
    }
    if (doctorNotificationNeeded != null) {
      list = list.where(
        (s) => s.doctorNotificationNeeded == doctorNotificationNeeded,
      );
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((s) => matchesQuery(s, q));
    }

    final result = List<PhysiotherapySessionNote>.from(list);
    result.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return result;
  }
}
