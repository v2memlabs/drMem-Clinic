import '../models/appointment.dart';
import 'appointment_repository_contract.dart';

/// Supabase randevu repository — pasif iskelet (Faz 2+).
class SupabaseAppointmentRepositoryStub implements AppointmentRepositoryContract {
  const SupabaseAppointmentRepositoryStub();

  @override
  List<Appointment> getAll() => const [];

  @override
  List<Appointment> getByPatientId(String patientId) => const [];

  @override
  Appointment? getById(String id) => null;

  @override
  List<Appointment> getToday() => const [];

  @override
  List<Appointment> getThisWeek() => const [];

  @override
  List<Appointment> search(String query) => const [];

  @override
  int count() => 0;

  @override
  int countToday() => 0;

  @override
  void add(Appointment appointment) {}

  @override
  bool update(Appointment appointment) => false;
}
