import '../models/appointment.dart';

/// Randevu → muayene başlatma — görünürlük, durum ve route kuralları.
abstract final class AppointmentClinicalHandoff {
  static const String startEncounterLabel = 'Muayene Başlat';

  static bool canShowStartEncounter({
    required bool canEditClinicalEncounters,
    required String? patientId,
    required AppointmentStatus status,
  }) {
    if (!canEditClinicalEncounters) return false;
    if (patientId == null || patientId.trim().isEmpty) return false;
    switch (status) {
      case AppointmentStatus.planlandi:
      case AppointmentStatus.ertelendi:
      case AppointmentStatus.geldi:
        return true;
      case AppointmentStatus.iptal:
      case AppointmentStatus.gelmedi:
        return false;
    }
  }

  static bool shouldUpdateStatusToArrived(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.planlandi:
      case AppointmentStatus.ertelendi:
        return true;
      case AppointmentStatus.geldi:
      case AppointmentStatus.iptal:
      case AppointmentStatus.gelmedi:
        return false;
    }
  }

  static Appointment withArrivedStatus(Appointment appointment) {
    if (!shouldUpdateStatusToArrived(appointment.status)) {
      return appointment;
    }
    return Appointment(
      id: appointment.id,
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      appointmentDateTime: appointment.appointmentDateTime,
      durationMinutes: appointment.durationMinutes,
      type: appointment.type,
      status: AppointmentStatus.geldi,
      reason: appointment.reason,
      controlDate: appointment.controlDate,
      notes: appointment.notes,
    );
  }

  static String buildNewEncounterLocation({
    required String patientId,
    required String appointmentId,
  }) {
    return Uri(
      path: '/clinical-records/new',
      queryParameters: {
        'patientId': patientId,
        'appointmentId': appointmentId,
      },
    ).toString();
  }
}
