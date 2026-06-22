import '../models/appointment.dart';
import 'appointment_repository_failure.dart';
import 'async_appointment_repository_contract.dart';

/// Supabase async randevu repository iskeleti — query yok, provider'a bağlı değil.
class SupabaseAsyncAppointmentRepositoryStub
    implements AsyncAppointmentRepositoryContract {
  const SupabaseAsyncAppointmentRepositoryStub();

  Never _notConfigured() => throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.notConfigured,
      );

  @override
  Future<List<Appointment>> getAll() async => _notConfigured();

  @override
  Future<List<Appointment>> getByPatientId(String patientId) async =>
      _notConfigured();

  @override
  Future<Appointment?> getById(String id) async => _notConfigured();

  @override
  Future<List<Appointment>> getToday() async => _notConfigured();

  @override
  Future<List<Appointment>> getForCalendarDay(DateTime day) async =>
      _notConfigured();

  @override
  Future<List<Appointment>> getThisWeek() async => _notConfigured();

  @override
  Future<List<Appointment>> search(String query) async => _notConfigured();

  @override
  Future<int> countToday() async => _notConfigured();

  @override
  Future<Appointment> add(Appointment appointment) async => _notConfigured();

  @override
  Future<Appointment> update(Appointment appointment) async => _notConfigured();

  @override
  Future<Appointment> cancel(String id) async => _notConfigured();

  @override
  Future<void> archiveAppointment(String id) async => _notConfigured();
}
