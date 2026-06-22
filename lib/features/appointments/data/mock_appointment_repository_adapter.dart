import '../models/appointment.dart';
import 'appointment_repository.dart';
import 'appointment_repository_contract.dart';

/// Mock implementasyon — [AppointmentRepository.instance] delegasyonu.
class MockAppointmentRepositoryAdapter implements AppointmentRepositoryContract {
  AppointmentRepository get _delegate => AppointmentRepository.instance;

  @override
  List<Appointment> getAll() => _delegate.getAll();

  @override
  List<Appointment> getByPatientId(String patientId) =>
      _delegate.getByPatientId(patientId);

  @override
  Appointment? getById(String id) => _delegate.getById(id);

  @override
  List<Appointment> getToday() => _delegate.getToday();

  @override
  List<Appointment> getThisWeek() => _delegate.getThisWeek();

  @override
  List<Appointment> search(String query) => _delegate.search(query);

  @override
  int count() => _delegate.count();

  @override
  int countToday() => _delegate.countToday();

  @override
  void add(Appointment appointment) => _delegate.add(appointment);

  @override
  bool update(Appointment appointment) => _delegate.update(appointment);
}
