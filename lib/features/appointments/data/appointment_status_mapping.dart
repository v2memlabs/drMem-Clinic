import '../models/appointment.dart';

/// [AppointmentStatus] ↔ Supabase `status` text.
abstract final class AppointmentStatusMapping {
  static const String planned = 'planned';
  static const String arrived = 'arrived';
  static const String noShow = 'no_show';
  static const String cancelled = 'cancelled';
  static const String postponed = 'postponed';

  static String toDb(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.planlandi:
        return planned;
      case AppointmentStatus.geldi:
        return arrived;
      case AppointmentStatus.gelmedi:
        return noShow;
      case AppointmentStatus.iptal:
        return cancelled;
      case AppointmentStatus.ertelendi:
        return postponed;
    }
  }

  static AppointmentStatus fromDb(String? value) {
    switch (value?.trim()) {
      case planned:
        return AppointmentStatus.planlandi;
      case arrived:
        return AppointmentStatus.geldi;
      case noShow:
        return AppointmentStatus.gelmedi;
      case cancelled:
        return AppointmentStatus.iptal;
      case postponed:
        return AppointmentStatus.ertelendi;
      default:
        return AppointmentStatus.planlandi;
    }
  }
}
