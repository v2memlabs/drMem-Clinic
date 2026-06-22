enum ReturnToSportStage {
  uygun_degil,
  agri_kontrolu,
  hareket_acikligi,
  kuvvetlendirme,
  kosuya_donus,
  saha_brans_calisma,
  temasli_antrenman,
  maca_donus,
}

class PhysiotherapySessionNote {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime sessionDate;
  final String physiotherapistName;
  final int painScore; // 0-10
  final String rangeOfMotionSummary;
  final String strengthSummary;
  final String functionalAssessment;
  final String exercisesPerformed;
  final String homeProgramCompliance;
  final String warningSigns;
  final ReturnToSportStage returnToSportStage;
  final bool doctorNotificationNeeded;
  final String notes;
  final String? referralId;

  PhysiotherapySessionNote({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.sessionDate,
    required this.physiotherapistName,
    required this.painScore,
    required this.rangeOfMotionSummary,
    required this.strengthSummary,
    required this.functionalAssessment,
    required this.exercisesPerformed,
    required this.homeProgramCompliance,
    required this.warningSigns,
    required this.returnToSportStage,
    this.doctorNotificationNeeded = false,
    this.notes = '',
    this.referralId,
  });

  String get returnToSportLabel => returnToSportStageLabel(returnToSportStage);
}

String returnToSportStageLabel(ReturnToSportStage stage) {
  switch (stage) {
    case ReturnToSportStage.uygun_degil:
      return 'Uygun Değil';
    case ReturnToSportStage.agri_kontrolu:
      return 'Ağrı Kontrolü';
    case ReturnToSportStage.hareket_acikligi:
      return 'Hareket Açıklığı';
    case ReturnToSportStage.kuvvetlendirme:
      return 'Kuvvetlendirme';
    case ReturnToSportStage.kosuya_donus:
      return 'Koşuya Dönüş';
    case ReturnToSportStage.saha_brans_calisma:
      return 'Saha / Branş Çalışması';
    case ReturnToSportStage.temasli_antrenman:
      return 'Temaslı Antrenman';
    case ReturnToSportStage.maca_donus:
      return 'Maça / Yarışa Dönüş';
  }
}
