import '../clinical_encounter/models/clinical_encounter.dart';

/// Muayene kaydından fizyoterapi yönlendirme formu için güvenli ön doldurma.
class PhysiotherapyReferralPrefill {
  PhysiotherapyReferralPrefill._();

  static const String unspecified = 'Belirtilmedi';

  static String diagnosisSummary(ClinicalEncounter e) {
    final finalDx = e.finalDiagnosis.trim();
    if (finalDx.isNotEmpty) return _truncate(finalDx, 200);
    final prelim = e.preliminaryDiagnosis.trim();
    if (prelim.isNotEmpty) return _truncate(prelim, 200);
    final impression = e.clinicalImpression.trim();
    if (impression.isNotEmpty) return _truncate(impression, 200);
    return unspecified;
  }

  static String treatmentGoal(ClinicalEncounter e) {
    final parts = <String>[];
    if (e.planTitle.trim().isNotEmpty) parts.add(e.planTitle.trim());
    if (e.conservativeTreatment.trim().isNotEmpty) {
      parts.add(_truncate(e.conservativeTreatment, 120));
    }
    if (e.physiotherapyReferral && e.exerciseRecommendation.trim().isNotEmpty) {
      parts.add(_truncate(e.exerciseRecommendation, 80));
    }
    if (e.sportsSectionEnabled && e.returnToSportGoal.trim().isNotEmpty) {
      parts.add('Spora dönüş hedefi: ${_truncate(e.returnToSportGoal, 80)}');
    }
    if (parts.isEmpty) return unspecified;
    return parts.join(' • ');
  }

  static String precautions(ClinicalEncounter e) {
    final parts = <String>[];
    if (e.warningNotes.trim().isNotEmpty) {
      parts.add(_truncate(e.warningNotes, 120));
    }
    if (e.patientInformationNote.trim().isNotEmpty) {
      parts.add(_truncate(e.patientInformationNote, 80));
    }
    return parts.isEmpty ? '' : parts.join('\n');
  }

  static String allowedActivities(ClinicalEncounter e) {
    if (e.exerciseRecommendation.trim().isNotEmpty) {
      return _truncate(e.exerciseRecommendation, 120);
    }
    return '';
  }

  static String restrictedActivities(ClinicalEncounter e) {
    if (e.surgeryRecommendation.trim().isNotEmpty) {
      return _truncate(e.surgeryRecommendation, 100);
    }
    return '';
  }

  static DateTime? targetReturnToSportDate(ClinicalEncounter e) {
    if (e.controlDate != null &&
        (e.sportsSectionEnabled || e.returnToSportGoal.trim().isNotEmpty)) {
      return e.controlDate;
    }
    return null;
  }

  static String referredBy(ClinicalEncounter e, String fallback) {
    final doctor = e.doctorName.trim();
    if (doctor.isNotEmpty) return doctor;
    return fallback;
  }

  static String _truncate(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }
}
