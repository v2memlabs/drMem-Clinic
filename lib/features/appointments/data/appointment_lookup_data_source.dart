import '../../../core/data/repository_registry.dart';
import '../models/appointment.dart';
import 'appointment_repository.dart';

/// Randevu okuma — mock sync veya remote async ([RepositoryRegistry.appointmentsAsync]).
abstract final class AppointmentLookupDataSource {
  static Future<Appointment?> findById(String appointmentId) async {
    final id = appointmentId.trim();
    if (id.isEmpty) return null;

    if (RepositoryRegistry.usesRemoteAppointments) {
      try {
        return await RepositoryRegistry.appointmentsAsync.getById(id);
      } catch (_) {
        return null;
      }
    }

    return AppointmentRepository.instance.getById(id);
  }

  static Future<List<Appointment>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    if (RepositoryRegistry.usesRemoteAppointments) {
      try {
        return await RepositoryRegistry.appointmentsAsync.getByPatientId(pid);
      } catch (_) {
        return const [];
      }
    }

    return AppointmentRepository.instance.getByPatientId(pid);
  }

  static Future<bool> exists(String appointmentId) async {
    final appointment = await findById(appointmentId);
    return appointment != null;
  }

  /// Mock-only modüller için senkron okuma.
  static Appointment? findByIdSync(String appointmentId) {
    final id = appointmentId.trim();
    if (id.isEmpty) return null;
    return AppointmentRepository.instance.getById(id);
  }
}
