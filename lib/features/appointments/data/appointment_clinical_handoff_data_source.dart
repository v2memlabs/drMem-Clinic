import 'appointment_clinical_handoff.dart';
import 'appointment_form_data_source.dart';
import 'appointment_form_user_messages.dart';
import 'appointment_repository_failure.dart';
import '../models/appointment.dart';

/// Randevu detayından muayene başlatma — durum güncelleme hattı.
abstract final class AppointmentClinicalHandoffDataSource {
  /// [planlandi]/[ertelendi] → [geldi]; diğer durumlarda güncelleme yapılmaz.
  static Future<Appointment> prepareForClinicalEncounter(
    Appointment appointment,
  ) async {
    if (!AppointmentClinicalHandoff.shouldUpdateStatusToArrived(
      appointment.status,
    )) {
      return appointment;
    }

    final updated =
        AppointmentClinicalHandoff.withArrivedStatus(appointment);
    try {
      return await AppointmentFormDataSource.update(updated);
    } on AppointmentRepositoryException catch (e) {
      throw AppointmentClinicalHandoffException(
        AppointmentFormUserMessages.forFailure(e.reason, isEdit: true),
      );
    } catch (_) {
      throw const AppointmentClinicalHandoffException(
        AppointmentClinicalHandoffUserMessages.statusUpdateFailure,
      );
    }
  }
}

class AppointmentClinicalHandoffException implements Exception {
  final String message;
  const AppointmentClinicalHandoffException(this.message);
}

abstract final class AppointmentClinicalHandoffUserMessages {
  static const String statusUpdateFailure =
      'Randevu durumu güncellenemedi. Muayene başlatılamadı.';
}
