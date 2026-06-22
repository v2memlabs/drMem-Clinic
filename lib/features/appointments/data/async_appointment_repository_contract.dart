import '../models/appointment.dart';

/// Remote randevu erişimi — async sözleşme (UI henüz bağlı değil).
///
/// `tenant_id` UI'dan gelmez — implementasyon [ActiveTenantContextStore] kullanır.
abstract interface class AsyncAppointmentRepositoryContract {
  Future<List<Appointment>> getAll();

  Future<List<Appointment>> getByPatientId(String patientId);

  Future<Appointment?> getById(String id);

  Future<List<Appointment>> getToday();

  /// İstanbul takvim günü [day] (y/m/d) içindeki aktif randevular.
  Future<List<Appointment>> getForCalendarDay(DateTime day);

  Future<List<Appointment>> getThisWeek();

  Future<List<Appointment>> search(String query);

  Future<int> countToday();

  Future<Appointment> add(Appointment appointment);

  Future<Appointment> update(Appointment appointment);

  Future<Appointment> cancel(String id);

  Future<void> archiveAppointment(String id);
}
