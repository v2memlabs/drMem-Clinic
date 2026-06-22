enum ReferralStatus { yeni, devam, tamamlandi, doktor_degerlendirmesi_bekliyor, iptal }

class PhysiotherapyReferral {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime referredAt;
  final String referredBy;
  final String physiotherapistName;
  final String? assignedPhysiotherapistProfileId;
  final String? appointmentId;
  final String diagnosisSummary;
  final String treatmentGoal;
  final String precautions;
  final String allowedActivities;
  final String restrictedActivities;
  final DateTime? targetReturnToSportDate;
  final ReferralStatus status;
  final String notes;
  final String? clinicalEncounterId;
  final DateTime? plannedStartDate;
  final String doctorSummary;

  PhysiotherapyReferral({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.referredAt,
    required this.referredBy,
    required this.physiotherapistName,
    this.assignedPhysiotherapistProfileId,
    this.appointmentId,
    required this.diagnosisSummary,
    required this.treatmentGoal,
    required this.precautions,
    required this.allowedActivities,
    required this.restrictedActivities,
    this.targetReturnToSportDate,
    this.status = ReferralStatus.yeni,
    this.notes = '',
    this.clinicalEncounterId,
    this.plannedStartDate,
    this.doctorSummary = '',
  });

  String get statusLabel => referralStatusLabel(status);

  bool get hasScheduledAppointment =>
      appointmentId != null && appointmentId!.trim().isNotEmpty;

  bool get isPendingPhysioAction =>
      status == ReferralStatus.yeni && !hasScheduledAppointment;

  PhysiotherapyReferral copyWith({
    String? id,
    String? patientId,
    String? patientName,
    DateTime? referredAt,
    String? referredBy,
    String? physiotherapistName,
    String? assignedPhysiotherapistProfileId,
    String? appointmentId,
    String? diagnosisSummary,
    String? treatmentGoal,
    String? precautions,
    String? allowedActivities,
    String? restrictedActivities,
    DateTime? targetReturnToSportDate,
    ReferralStatus? status,
    String? notes,
    String? clinicalEncounterId,
    DateTime? plannedStartDate,
    String? doctorSummary,
  }) {
    return PhysiotherapyReferral(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      referredAt: referredAt ?? this.referredAt,
      referredBy: referredBy ?? this.referredBy,
      physiotherapistName: physiotherapistName ?? this.physiotherapistName,
      assignedPhysiotherapistProfileId: assignedPhysiotherapistProfileId ??
          this.assignedPhysiotherapistProfileId,
      appointmentId: appointmentId ?? this.appointmentId,
      diagnosisSummary: diagnosisSummary ?? this.diagnosisSummary,
      treatmentGoal: treatmentGoal ?? this.treatmentGoal,
      precautions: precautions ?? this.precautions,
      allowedActivities: allowedActivities ?? this.allowedActivities,
      restrictedActivities: restrictedActivities ?? this.restrictedActivities,
      targetReturnToSportDate:
          targetReturnToSportDate ?? this.targetReturnToSportDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      clinicalEncounterId: clinicalEncounterId ?? this.clinicalEncounterId,
      plannedStartDate: plannedStartDate ?? this.plannedStartDate,
      doctorSummary: doctorSummary ?? this.doctorSummary,
    );
  }
}

String referralStatusLabel(ReferralStatus status) {
  switch (status) {
    case ReferralStatus.yeni:
      return 'Yeni Yönlendirme';
    case ReferralStatus.devam:
      return 'Devam Ediyor';
    case ReferralStatus.tamamlandi:
      return 'Tamamlandı';
    case ReferralStatus.doktor_degerlendirmesi_bekliyor:
      return 'Doktor Değerlendirmesi Bekliyor';
    case ReferralStatus.iptal:
      return 'İptal';
  }
}
