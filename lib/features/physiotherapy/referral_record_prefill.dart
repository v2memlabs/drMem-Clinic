import 'models/physiotherapy_referral.dart';

/// Yönlendirme kaydından seans/egzersiz formları için güvenli ön doldurma.
class ReferralRecordPrefill {
  ReferralRecordPrefill._();

  static String _truncate(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }

  static String sessionFunctionalAssessment(PhysiotherapyReferral r) {
    return _truncate(r.treatmentGoal, 200);
  }

  static String sessionNotes(PhysiotherapyReferral r) {
    final parts = <String>[
      'Tanı: ${_truncate(r.diagnosisSummary, 120)}',
      'Yönlendiren: ${r.referredBy.trim()}',
    ];
    if (r.notes.trim().isNotEmpty) {
      parts.add('Yönlendirme notu: ${_truncate(r.notes, 80)}');
    }
    return parts.join('\n');
  }

  static String sessionWarningSigns(PhysiotherapyReferral r) {
    final parts = <String>[];
    if (r.precautions.trim().isNotEmpty) {
      parts.add(_truncate(r.precautions, 120));
    }
    if (r.restrictedActivities.trim().isNotEmpty) {
      parts.add('Kısıt: ${_truncate(r.restrictedActivities, 80)}');
    }
    return parts.join('\n');
  }

  static String sessionExercisesPerformed(PhysiotherapyReferral r) {
    if (r.allowedActivities.trim().isEmpty) return '';
    return _truncate(r.allowedActivities, 200);
  }

  static String exerciseTitle(PhysiotherapyReferral r) {
    final name = r.patientName.trim().isEmpty ? 'Hasta' : r.patientName.trim();
    return 'Egzersiz Programı — $name';
  }

  static String exerciseWarnings(PhysiotherapyReferral r) {
    final parts = <String>[];
    if (r.precautions.trim().isNotEmpty) {
      parts.add(_truncate(r.precautions, 120));
    }
    if (r.restrictedActivities.trim().isNotEmpty) {
      parts.add('Kısıtlanan: ${_truncate(r.restrictedActivities, 100)}');
    }
    return parts.join('\n');
  }

  static String exerciseHomeInstructions(PhysiotherapyReferral r) {
    if (r.allowedActivities.trim().isEmpty) return '';
    return _truncate(r.allowedActivities, 200);
  }

  static String formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
