import '../models/appointment.dart';
import '../../../core/session/record_ownership_context.dart';
import 'appointment_repository.dart';
import 'appointment_repository_contract.dart';
import 'async_appointment_repository_contract.dart';

/// Mock sync repository → async contract (anında tamamlanan Future).
///
/// Aktif UI bağlı değil; ileride provider switch için hazır.
class MockAsyncAppointmentRepositoryAdapter
    implements AsyncAppointmentRepositoryContract {
  AppointmentRepositoryContract get _sync => AppointmentRepository.instance;

  @override
  Future<List<Appointment>> getAll() async => _sync.getAll();

  @override
  Future<List<Appointment>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<Appointment?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<Appointment>> getToday() async => _sync.getToday();

  @override
  Future<List<Appointment>> getForCalendarDay(DateTime day) async {
    final target = DateTime(day.year, day.month, day.day);
    final all = await _sync.getAll();
    return all.where((a) {
      final local = a.appointmentDateTime.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      return d == target;
    }).toList();
  }

  @override
  Future<List<Appointment>> getThisWeek() async => _sync.getThisWeek();

  @override
  Future<List<Appointment>> search(String query) async => _sync.search(query);

  @override
  Future<int> countToday() async => _sync.countToday();

  @override
  Future<Appointment> add(Appointment appointment) async {
    final profileId = RecordOwnershipContext.currentProfileId();
    final owned = Appointment(
      id: appointment.id,
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      appointmentDateTime: appointment.appointmentDateTime,
      durationMinutes: appointment.durationMinutes,
      type: appointment.type,
      status: appointment.status,
      reason: appointment.reason,
      controlDate: appointment.controlDate,
      notes: appointment.notes,
      assignedDoctorProfileId:
          appointment.assignedDoctorProfileId ?? profileId,
      assignedDoctorName: appointment.assignedDoctorName ??
          RecordOwnershipContext.currentDisplayName(),
      assignedPhysiotherapistProfileId:
          appointment.assignedPhysiotherapistProfileId,
      createdByProfileId: profileId,
    );
    _sync.add(owned);
    return owned;
  }

  @override
  Future<Appointment> update(Appointment appointment) async {
    final ok = _sync.update(appointment);
    if (!ok) {
      throw StateError('Mock appointment update failed: ${appointment.id}');
    }
    return appointment;
  }

  @override
  Future<Appointment> cancel(String id) async {
    final existing = _sync.getById(id);
    if (existing == null) {
      throw StateError('Mock appointment cancel failed: $id');
    }
    final cancelled = Appointment(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      appointmentDateTime: existing.appointmentDateTime,
      durationMinutes: existing.durationMinutes,
      type: existing.type,
      status: AppointmentStatus.iptal,
      reason: existing.reason,
      controlDate: existing.controlDate,
      notes: existing.notes,
      assignedDoctorProfileId: existing.assignedDoctorProfileId,
      assignedDoctorName: existing.assignedDoctorName,
      assignedPhysiotherapistProfileId: existing.assignedPhysiotherapistProfileId,
      createdByProfileId: existing.createdByProfileId,
    );
    _sync.update(cancelled);
    return cancelled;
  }

  @override
  Future<void> archiveAppointment(String id) async {
    // Mock'ta soft delete yok — remote v1 hazırlığı; no-op.
  }
}
