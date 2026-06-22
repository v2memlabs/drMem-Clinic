enum AppointmentType {
  ilkMuayene,
  kontrol,
  fizikTedavi,
  girisim,
  ameliyatSonrasi
}

enum AppointmentStatus { planlandi, geldi, gelmedi, iptal, ertelendi }

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientFileNumber;
  final DateTime appointmentDateTime;
  final int durationMinutes;
  final AppointmentType type;
  final AppointmentStatus status;
  final String reason;
  final DateTime? controlDate;
  final String notes;
  final String? assignedDoctorProfileId;
  final String? assignedDoctorName;
  final String? assignedPhysiotherapistProfileId;
  final String? createdByProfileId;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientFileNumber,
    required this.appointmentDateTime,
    required this.durationMinutes,
    required this.type,
    required this.status,
    required this.reason,
    this.controlDate,
    this.notes = '',
    this.assignedDoctorProfileId,
    this.assignedDoctorName,
    this.assignedPhysiotherapistProfileId,
    this.createdByProfileId,
  });
}

String appointmentTypeLabel(AppointmentType type) {
  switch (type) {
    case AppointmentType.ilkMuayene:
      return 'İlk Muayene';
    case AppointmentType.kontrol:
      return 'Kontrol';
    case AppointmentType.fizikTedavi:
      return 'Fizik Tedavi';
    case AppointmentType.girisim:
      return 'Girişim';
    case AppointmentType.ameliyatSonrasi:
      return 'Ameliyat Sonrası Kontrol';
  }
}

String appointmentStatusLabel(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.planlandi:
      return 'Planlandı';
    case AppointmentStatus.geldi:
      return 'Geldi';
    case AppointmentStatus.gelmedi:
      return 'Gelmedi';
    case AppointmentStatus.iptal:
      return 'İptal';
    case AppointmentStatus.ertelendi:
      return 'Ertelendi';
  }
}
