import '../../../core/data/repository_registry.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import 'appointment_detail_load_result.dart';
import 'appointment_detail_user_messages.dart';
import 'appointment_repository_failure.dart';

/// Randevu detay — [RepositoryRegistry.appointmentsAsync].getById.
abstract final class AppointmentDetailDataSource {
  static Future<AppointmentDetailLoadResult> loadById(String id) async {
    try {
      final appointment =
          await RepositoryRegistry.appointmentsAsync.getById(id);
      if (appointment == null) {
        return AppointmentDetailLoadResult.notFound();
      }

      final fileNumber = await _resolvePatientFileNumber(appointment.patientId);

      return AppointmentDetailLoadResult.success(
        appointment: appointment,
        patientFileNumber: fileNumber,
      );
    } on AppointmentRepositoryException catch (e) {
      if (e.reason == AppointmentRepositoryFailure.notFound) {
        return AppointmentDetailLoadResult.notFound();
      }
      return AppointmentDetailLoadResult.failure(
        AppointmentDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return AppointmentDetailLoadResult.failure(
        AppointmentDetailUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<String?> _resolvePatientFileNumber(String patientId) async {
    return PatientLookupDataSource.resolveFileNumber(patientId);
  }
}
