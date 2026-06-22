enum PostOpPhase {
  erkenPostOp,
  hafta0_2,
  hafta2_6,
  hafta6_12,
  ay3VeSonrasi,
  sporaDonus,
  genelProtokol,
}

enum PostOpProtocolStatus {
  taslak,
  aktif,
  hastayaVerildi,
  fizyoterapistlePaylasildi,
  guncellenecek,
  tamamlandi,
}

class PostOpProtocol {
  final String id;
  final String patientId;
  final String patientName;
  final String? surgeryNoteId;
  final DateTime createdAt;
  final String protocolTitle;
  final String diagnosisOrProcedureSummary;
  final PostOpPhase phase;
  final String weightBearingStatus;
  final String rangeOfMotionLimits;
  final String braceOrImmobilization;
  final String woundCareNotes;
  final String medicationOrPainControlNotes;
  final String physiotherapyInstructions;
  final String exerciseRestrictions;
  final String redFlags;
  final DateTime? controlDate;
  final String returnToSportEstimate;
  final String createdBy;
  final PostOpProtocolStatus status;
  final String notes;

  const PostOpProtocol({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.surgeryNoteId,
    required this.createdAt,
    required this.protocolTitle,
    required this.diagnosisOrProcedureSummary,
    required this.phase,
    required this.weightBearingStatus,
    required this.rangeOfMotionLimits,
    required this.braceOrImmobilization,
    required this.woundCareNotes,
    required this.medicationOrPainControlNotes,
    required this.physiotherapyInstructions,
    required this.exerciseRestrictions,
    required this.redFlags,
    this.controlDate,
    required this.returnToSportEstimate,
    required this.createdBy,
    required this.status,
    this.notes = '',
  });
}

String postOpPhaseLabel(PostOpPhase phase) {
  switch (phase) {
    case PostOpPhase.erkenPostOp:
      return 'Erken Post-op';
    case PostOpPhase.hafta0_2:
      return '0-2 Hafta';
    case PostOpPhase.hafta2_6:
      return '2-6 Hafta';
    case PostOpPhase.hafta6_12:
      return '6-12 Hafta';
    case PostOpPhase.ay3VeSonrasi:
      return '3 Ay ve Sonrası';
    case PostOpPhase.sporaDonus:
      return 'Spora Dönüş';
    case PostOpPhase.genelProtokol:
      return 'Genel Protokol';
  }
}

String postOpProtocolStatusLabel(PostOpProtocolStatus status) {
  switch (status) {
    case PostOpProtocolStatus.taslak:
      return 'Taslak';
    case PostOpProtocolStatus.aktif:
      return 'Aktif';
    case PostOpProtocolStatus.hastayaVerildi:
      return 'Hastaya Verildi';
    case PostOpProtocolStatus.fizyoterapistlePaylasildi:
      return 'Fizyoterapistle Paylaşıldı';
    case PostOpProtocolStatus.guncellenecek:
      return 'Güncellenecek';
    case PostOpProtocolStatus.tamamlandi:
      return 'Tamamlandı';
  }
}
