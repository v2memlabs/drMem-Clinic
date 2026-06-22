import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import '../models/physiotherapy_session_note.dart';
import 'mock_physiotherapy_referrals.dart';
import 'mock_physiotherapy_session_notes.dart';

class PhysiotherapyRepository {
  PhysiotherapyRepository._();

  static final PhysiotherapyRepository instance = PhysiotherapyRepository._();

  // --- Yönlendirmeler ---

  List<PhysiotherapyReferral> getReferrals() => List.unmodifiable(mockPhysiotherapyReferrals);

  PhysiotherapyReferral? getReferralById(String id) {
    for (final referral in mockPhysiotherapyReferrals) {
      if (referral.id == id) return referral;
    }
    return null;
  }

  List<PhysiotherapyReferral> getReferralsByPatientId(String patientId) =>
      mockPhysiotherapyReferrals.where((r) => r.patientId == patientId).toList();

  List<PhysiotherapyReferral> searchReferrals(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getReferrals();
    return mockPhysiotherapyReferrals.where((r) => _referralMatchesQuery(r, q)).toList();
  }

  List<PhysiotherapyReferral> getFilteredReferrals({
    String? patientId,
    String? query,
    String? statusFilter,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) {
    Iterable<PhysiotherapyReferral> list = mockPhysiotherapyReferrals;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((r) => r.patientId == patientId);
    }
    if (statusEnumFilter != null) {
      list = list.where((r) => r.status == statusEnumFilter);
    } else if (statusFilter != null && statusFilter.isNotEmpty) {
      final sf = statusFilter.toLowerCase();
      list = list.where((r) => r.statusLabel.toLowerCase().contains(sf));
    }
    if (physiotherapistFilter != null && physiotherapistFilter.isNotEmpty) {
      final pf = physiotherapistFilter.toLowerCase();
      list = list.where((r) => r.physiotherapistName.toLowerCase().contains(pf));
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((r) => _referralMatchesQuery(r, q));
    }

    return List<PhysiotherapyReferral>.from(list);
  }

  void addReferral(PhysiotherapyReferral referral) =>
      mockPhysiotherapyReferrals.insert(0, referral);

  PhysiotherapyReferral updateReferralSafe(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) {
    final index = mockPhysiotherapyReferrals.indexWhere((r) => r.id == id);
    if (index < 0) {
      throw StateError('Referral not found');
    }
    final current = mockPhysiotherapyReferrals[index];
    final updated = current.copyWith(
      status: update.status ?? current.status,
      notes: update.notesSafe ?? current.notes,
      plannedStartDate: update.plannedStartDate ?? current.plannedStartDate,
      assignedPhysiotherapistProfileId:
          update.assignedPhysiotherapistProfileId ??
              current.assignedPhysiotherapistProfileId,
      appointmentId: update.appointmentId ?? current.appointmentId,
    );
    mockPhysiotherapyReferrals[index] = updated;
    return updated;
  }

  bool _referralMatchesQuery(PhysiotherapyReferral r, String q) {
    if (r.patientName.toLowerCase().contains(q)) return true;
    if (r.physiotherapistName.toLowerCase().contains(q)) return true;
    if (r.diagnosisSummary.toLowerCase().contains(q)) return true;
    if (r.treatmentGoal.toLowerCase().contains(q)) return true;
    if (r.statusLabel.toLowerCase().contains(q)) return true;
    if (r.referredBy.toLowerCase().contains(q)) return true;
    if (r.notes.toLowerCase().contains(q)) return true;
    return false;
  }

  // --- Seans notları ---

  List<PhysiotherapySessionNote> getSessionNotes() =>
      List.unmodifiable(mockPhysiotherapySessionNotes);

  PhysiotherapySessionNote? getSessionNoteById(String id) {
    for (final note in mockPhysiotherapySessionNotes) {
      if (note.id == id) return note;
    }
    return null;
  }

  List<PhysiotherapySessionNote> getSessionNotesByPatientId(String patientId) =>
      mockPhysiotherapySessionNotes.where((s) => s.patientId == patientId).toList();

  /// Hasta bazlı seanslar; [sessionDate] yeniden eskiye, en fazla [limit] kayıt.
  List<PhysiotherapySessionNote> getRecentSessionNotesByPatientId(
    String patientId, {
    int limit = 5,
  }) {
    final list = List<PhysiotherapySessionNote>.from(
      getSessionNotesByPatientId(patientId),
    )..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  List<PhysiotherapySessionNote> getSessionNotesByReferralId(String referralId) {
    final list = mockPhysiotherapySessionNotes
        .where((s) => s.referralId == referralId)
        .toList();
    list.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return list;
  }

  List<PhysiotherapySessionNote> searchSessionNotes(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getSessionNotes();
    return mockPhysiotherapySessionNotes.where((s) => _sessionMatchesQuery(s, q)).toList();
  }

  List<PhysiotherapySessionNote> getFilteredSessionNotes({
    String? patientId,
    String? query,
    String? returnToSportStageFilter,
    ReturnToSportStage? returnToSportStageEnumFilter,
    bool? doctorNotificationNeeded,
  }) {
    Iterable<PhysiotherapySessionNote> list = mockPhysiotherapySessionNotes;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((s) => s.patientId == patientId);
    }
    if (returnToSportStageEnumFilter != null) {
      list = list.where((s) => s.returnToSportStage == returnToSportStageEnumFilter);
    } else if (returnToSportStageFilter != null && returnToSportStageFilter.isNotEmpty) {
      final sf = returnToSportStageFilter.toLowerCase();
      list = list.where((s) => s.returnToSportLabel.toLowerCase().contains(sf));
    }
    if (doctorNotificationNeeded != null) {
      list = list.where((s) => s.doctorNotificationNeeded == doctorNotificationNeeded);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((s) => _sessionMatchesQuery(s, q));
    }

    return List<PhysiotherapySessionNote>.from(list);
  }

  void addSessionNote(PhysiotherapySessionNote note) =>
      mockPhysiotherapySessionNotes.insert(0, note);

  bool _sessionMatchesQuery(PhysiotherapySessionNote s, String q) {
    if (s.patientName.toLowerCase().contains(q)) return true;
    if (s.physiotherapistName.toLowerCase().contains(q)) return true;
    if (s.returnToSportLabel.toLowerCase().contains(q)) return true;
    if (s.notes.toLowerCase().contains(q)) return true;
    if (s.exercisesPerformed.toLowerCase().contains(q)) return true;
    if (s.functionalAssessment.toLowerCase().contains(q)) return true;
    return false;
  }
}
