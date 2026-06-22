import '../../../core/data/repository_registry.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import '../../patients/models/patient.dart';
import '../models/appointment.dart';
import 'appointment_repository_failure.dart';

/// Randevu form — async create/update/cancel ([RepositoryRegistry.appointmentsAsync]).
abstract final class AppointmentFormDataSource {
  static Future<Appointment?> loadForEdit(String id) async {
    try {
      return await RepositoryRegistry.appointmentsAsync.getById(id);
    } on AppointmentRepositoryException {
      rethrow;
    } catch (_) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.unknown,
      );
    }
  }

  static Future<Appointment> create(Appointment draft) async {
    _assertValidDateTime(draft.appointmentDateTime);
    final toAdd = _prepareCreateDraft(draft);
    try {
      return await RepositoryRegistry.appointmentsAsync.add(toAdd);
    } on AppointmentRepositoryException {
      rethrow;
    } catch (_) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.unknown,
      );
    }
  }

  static Future<Appointment> update(Appointment appointment) async {
    _assertValidDateTime(appointment.appointmentDateTime);
    try {
      return await RepositoryRegistry.appointmentsAsync.update(appointment);
    } on AppointmentRepositoryException {
      rethrow;
    } catch (_) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.unknown,
      );
    }
  }

  /// İptal — `status: cancelled`. UI henüz bağlı değil.
  static Future<Appointment> cancel(String id) async {
    try {
      return await RepositoryRegistry.appointmentsAsync.cancel(id);
    } on AppointmentRepositoryException {
      rethrow;
    } catch (_) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.unknown,
      );
    }
  }

  static Future<bool> patientExists(String patientId) async {
    return PatientLookupDataSource.exists(patientId);
  }

  static Future<String> resolvePatientName({
    required String patientId,
    Patient? selectedPatient,
  }) async {
    return PatientLookupDataSource.resolveName(
      patientId: patientId,
      selectedPatient: selectedPatient,
    );
  }

  static Appointment _prepareCreateDraft(Appointment draft) {
    if (RepositoryRegistry.usesRemoteAppointments) {
      return Appointment(
        id: '',
        patientId: draft.patientId,
        patientName: draft.patientName,
        appointmentDateTime: draft.appointmentDateTime,
        durationMinutes: draft.durationMinutes,
        type: draft.type,
        status: draft.status,
        reason: draft.reason,
        controlDate: draft.controlDate,
        notes: draft.notes,
        assignedDoctorProfileId: draft.assignedDoctorProfileId,
        assignedDoctorName: draft.assignedDoctorName,
        assignedPhysiotherapistProfileId: draft.assignedPhysiotherapistProfileId,
        createdByProfileId: draft.createdByProfileId,
      );
    }

    if (draft.id.isEmpty) {
      return Appointment(
        id: 'a${DateTime.now().millisecondsSinceEpoch}',
        patientId: draft.patientId,
        patientName: draft.patientName,
        appointmentDateTime: draft.appointmentDateTime,
        durationMinutes: draft.durationMinutes,
        type: draft.type,
        status: draft.status,
        reason: draft.reason,
        controlDate: draft.controlDate,
        notes: draft.notes,
      );
    }
    return draft;
  }

  static void _assertValidDateTime(DateTime dateTime) {
    if (dateTime.year < 1900 || dateTime.year > 2100) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.invalidDateTime,
      );
    }
  }
}
