import '../models/appointment.dart';

/// [AppointmentType] ↔ Supabase `appointment_type` text.
abstract final class AppointmentTypeMapping {
  static const String firstVisit = 'first_visit';
  static const String followUp = 'follow_up';
  static const String physiotherapy = 'physiotherapy';
  static const String procedure = 'procedure';
  static const String postOpFollowUp = 'post_op_follow_up';

  static String toDb(AppointmentType type) {
    switch (type) {
      case AppointmentType.ilkMuayene:
        return firstVisit;
      case AppointmentType.kontrol:
        return followUp;
      case AppointmentType.fizikTedavi:
        return physiotherapy;
      case AppointmentType.girisim:
        return procedure;
      case AppointmentType.ameliyatSonrasi:
        return postOpFollowUp;
    }
  }

  static AppointmentType fromDb(String? value) {
    switch (value?.trim()) {
      case firstVisit:
        return AppointmentType.ilkMuayene;
      case followUp:
        return AppointmentType.kontrol;
      case physiotherapy:
        return AppointmentType.fizikTedavi;
      case procedure:
        return AppointmentType.girisim;
      case postOpFollowUp:
        return AppointmentType.ameliyatSonrasi;
      default:
        return AppointmentType.kontrol;
    }
  }
}
