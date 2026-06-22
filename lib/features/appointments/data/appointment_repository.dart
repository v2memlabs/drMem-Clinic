import '../models/appointment.dart';
import 'appointment_ownership.dart';
import 'appointment_repository_contract.dart';
import 'mock_appointments.dart';

// TODO(saas-migration): UI → [AppointmentRepositoryProvider.current].

class AppointmentRepository implements AppointmentRepositoryContract {
  AppointmentRepository._();

  static final AppointmentRepository instance = AppointmentRepository._();

  List<Appointment> _visible(Iterable<Appointment> source) =>
      source.where(AppointmentOwnership.isVisibleToCurrentUser).toList();

  @override
  List<Appointment> getAll() => List.unmodifiable(_visible(mockAppointments));

  @override
  int count() => mockAppointments.length;

  @override
  int countToday() => getToday().length;

  @override
  Appointment? getById(String id) {
    for (final a in mockAppointments) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  List<Appointment> getByPatientId(String patientId) =>
      _visible(mockAppointments.where((a) => a.patientId == patientId));

  @override
  List<Appointment> getToday() {
    final now = DateTime.now();
    return _visible(
      mockAppointments.where(
        (a) =>
            a.appointmentDateTime.year == now.year &&
            a.appointmentDateTime.month == now.month &&
            a.appointmentDateTime.day == now.day,
      ),
    );
  }

  @override
  List<Appointment> getThisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _visible(
      mockAppointments.where(
        (a) =>
            !a.appointmentDateTime.isBefore(start) &&
            !a.appointmentDateTime.isAfter(end),
      ),
    );
  }

  @override
  List<Appointment> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _visible(
      mockAppointments.where((a) {
        if (a.patientName.toLowerCase().contains(q)) return true;
        if (a.reason.toLowerCase().contains(q)) return true;
        return false;
      }),
    );
  }

  @override
  void add(Appointment appointment) => mockAppointments.insert(0, appointment);

  @override
  bool update(Appointment appointment) {
    final index = mockAppointments.indexWhere((a) => a.id == appointment.id);
    if (index < 0) return false;
    mockAppointments[index] = appointment;
    return true;
  }
}
