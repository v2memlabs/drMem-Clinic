import '../../icd/models/icd_code.dart';
import 'clinical_treatment_approach.dart';

enum ClinicalVisitType {
  ilkMuayene,
  kontrol,
  postOpKontrol,
  ikinciGorus,
  girisimOncesiDegerlendirme,
  genelOrtopedikDegerlendirme;

  String get label {
    switch (this) {
      case ClinicalVisitType.ilkMuayene:
        return 'İlk Muayene';
      case ClinicalVisitType.kontrol:
        return 'Kontrol';
      case ClinicalVisitType.postOpKontrol:
        return 'Post-op Kontrol';
      case ClinicalVisitType.ikinciGorus:
        return 'İkinci Görüş';
      case ClinicalVisitType.girisimOncesiDegerlendirme:
        return 'Girişim Öncesi Değerlendirme';
      case ClinicalVisitType.genelOrtopedikDegerlendirme:
        return 'Genel Ortopedik Değerlendirme';
    }
  }
}

enum ClinicalEncounterStatus {
  taslak,
  tamamlandi,
  kontrolPlanlandi,
  fizyoterapiyeYonlendirildi,
  ameliyatPlanlandi;

  String get label {
    switch (this) {
      case ClinicalEncounterStatus.taslak:
        return 'Taslak';
      case ClinicalEncounterStatus.tamamlandi:
        return 'Tamamlandı';
      case ClinicalEncounterStatus.kontrolPlanlandi:
        return 'Kontrol Planlandı';
      case ClinicalEncounterStatus.fizyoterapiyeYonlendirildi:
        return 'Fizyoterapiye Yönlendirildi';
      case ClinicalEncounterStatus.ameliyatPlanlandi:
        return 'Ameliyat / Girişim Planlandı';
    }
  }
}

enum ClinicalBodyRegion {
  diz,
  omuz,
  kalca,
  ayakBilegi,
  ayak,
  dirsek,
  elBilegi,
  el,
  omurga,
  genel,
  diger;

  String get label {
    switch (this) {
      case ClinicalBodyRegion.diz:
        return 'Diz';
      case ClinicalBodyRegion.omuz:
        return 'Omuz';
      case ClinicalBodyRegion.kalca:
        return 'Kalça';
      case ClinicalBodyRegion.ayakBilegi:
        return 'Ayak Bileği';
      case ClinicalBodyRegion.ayak:
        return 'Ayak';
      case ClinicalBodyRegion.dirsek:
        return 'Dirsek';
      case ClinicalBodyRegion.elBilegi:
        return 'El Bileği';
      case ClinicalBodyRegion.el:
        return 'El';
      case ClinicalBodyRegion.omurga:
        return 'Omurga';
      case ClinicalBodyRegion.genel:
        return 'Genel';
      case ClinicalBodyRegion.diger:
        return 'Diğer';
    }
  }
}

enum ClinicalSide {
  sag,
  sol,
  bilateral,
  uygunDegil;

  String get label {
    switch (this) {
      case ClinicalSide.sag:
        return 'Sağ';
      case ClinicalSide.sol:
        return 'Sol';
      case ClinicalSide.bilateral:
        return 'Bilateral';
      case ClinicalSide.uygunDegil:
        return 'Uygun Değil';
    }
  }
}

enum ClinicalDiagnosisType {
  travmatik,
  dejeneratif,
  asiriKullanim,
  postOp,
  inflamatuvar,
  diger;

  String get label {
    switch (this) {
      case ClinicalDiagnosisType.travmatik:
        return 'Travmatik';
      case ClinicalDiagnosisType.dejeneratif:
        return 'Dejeneratif';
      case ClinicalDiagnosisType.asiriKullanim:
        return 'Aşırı Kullanım';
      case ClinicalDiagnosisType.postOp:
        return 'Post-op';
      case ClinicalDiagnosisType.inflamatuvar:
        return 'İnflamatuvar';
      case ClinicalDiagnosisType.diger:
        return 'Diğer';
    }
  }
}

class ClinicalEncounter {
  final String id;
  /// Klinik belgelerde referans — örn. `M-2026-00001`.
  final String protocolNumber;
  final String patientId;
  final String patientName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String doctorName;
  final ClinicalEncounterStatus status;
  final ClinicalVisitType visitType;
  final ClinicalBodyRegion bodyRegion;
  final ClinicalSide side;

  final String chiefComplaint;
  final String complaintDuration;
  final bool traumaHistory;
  final String painLocation;
  final String painCharacter;
  final int vasScore;
  final bool nightPain;
  final String activityRelation;
  final String previousTreatments;
  final String medications;
  final String allergies;
  final String comorbidities;
  final String previousSurgeries;
  final String generalNotes;

  final bool sportsSectionEnabled;
  final String sportBranch;
  final String amateurOrProfessional;
  final String trainingFrequency;
  final String patientExpectation;
  final String returnToSportGoal;
  final bool sportsRelated;
  final String returnToSportPlan;

  final String inspection;
  final String palpation;
  final String rangeOfMotion;
  final String muscleStrength;
  final String stabilityTests;
  final String specialTests;
  final String neurovascularStatus;
  final String comparisonWithOtherSide;
  final String clinicalImpression;

  final String imagingSummary;
  final String imagingDoctorComment;
  final String attachedFileNote;

  final String preliminaryDiagnosis;
  final String finalDiagnosis;
  final String differentialDiagnosis;
  final ClinicalDiagnosisType diagnosisType;
  final String icdCode;
  final String icdTitle;

  final String planTitle;
  final String conservativeTreatment;
  final String medicationNotes;
  final String injectionOrProcedurePlan;
  final bool physiotherapyReferral;
  final String exerciseRecommendation;
  final String imagingRequest;
  final DateTime? controlDate;
  final String surgeryRecommendation;
  final String patientInformationNote;
  final String warningNotes;

  final String internalDoctorNote;
  final String orthosisNotes;
  final ClinicalTreatmentApproach? treatmentApproach;
  final String? createdByProfileId;

  const ClinicalEncounter({
    required this.id,
    this.protocolNumber = '',
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.updatedAt,
    required this.doctorName,
    required this.status,
    required this.visitType,
    required this.bodyRegion,
    required this.side,
    required this.chiefComplaint,
    required this.complaintDuration,
    required this.traumaHistory,
    required this.painLocation,
    required this.painCharacter,
    required this.vasScore,
    required this.nightPain,
    required this.activityRelation,
    required this.previousTreatments,
    required this.medications,
    required this.allergies,
    required this.comorbidities,
    required this.previousSurgeries,
    required this.generalNotes,
    required this.sportsSectionEnabled,
    required this.sportBranch,
    required this.amateurOrProfessional,
    required this.trainingFrequency,
    required this.patientExpectation,
    required this.returnToSportGoal,
    required this.sportsRelated,
    required this.returnToSportPlan,
    required this.inspection,
    required this.palpation,
    required this.rangeOfMotion,
    required this.muscleStrength,
    required this.stabilityTests,
    required this.specialTests,
    required this.neurovascularStatus,
    required this.comparisonWithOtherSide,
    required this.clinicalImpression,
    required this.imagingSummary,
    required this.imagingDoctorComment,
    required this.attachedFileNote,
    required this.preliminaryDiagnosis,
    required this.finalDiagnosis,
    required this.differentialDiagnosis,
    required this.diagnosisType,
    required this.icdCode,
    this.icdTitle = '',
    required this.planTitle,
    required this.conservativeTreatment,
    required this.medicationNotes,
    required this.injectionOrProcedurePlan,
    required this.physiotherapyReferral,
    required this.exerciseRecommendation,
    required this.imagingRequest,
    this.controlDate,
    required this.surgeryRecommendation,
    required this.patientInformationNote,
    required this.warningNotes,
    required this.internalDoctorNote,
    this.orthosisNotes = '',
    this.treatmentApproach,
    this.createdByProfileId,
  });

  String get treatmentPlanSummary {
    final parts = <String>[];
    if (planTitle.isNotEmpty) parts.add(planTitle);
    if (conservativeTreatment.isNotEmpty) {
      parts.add(
        conservativeTreatment.length > 60
            ? '${conservativeTreatment.substring(0, 60)}…'
            : conservativeTreatment,
      );
    }
    return parts.isEmpty ? '-' : parts.join(' • ');
  }

  /// ICD kodu ve başlık birleşik gösterim (başlık yoksa sadece kod).
  String get icdDisplay {
    final line = formatIcdDisplay(icdCode, icdTitle.isEmpty ? null : icdTitle);
    return line.isEmpty ? '-' : line;
  }

  bool get hasProtocolNumber => protocolNumber.trim().isNotEmpty;

  String get displayProtocolNumber =>
      hasProtocolNumber ? protocolNumber.trim() : '—';
}
