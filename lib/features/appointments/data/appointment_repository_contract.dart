import '../models/appointment.dart';

/// Randevu veri erişim sözleşmesi.
///
/// Tenant izolasyonu: remote implementasyon [ActiveTenantContextStore] kullanır.
/// Async sözleşme: [AsyncAppointmentRepositoryContract].
abstract interface class AppointmentRepositoryContract {
  // --- Okuma ---

  List<Appointment> getAll();

  List<Appointment> getByPatientId(String patientId);

  Appointment? getById(String id);

  /// Liste ekranı / dashboard — bugünkü randevular.
  List<Appointment> getToday();

  /// Bu hafta (Pazartesi başlangıçlı mevcut mock mantık).
  List<Appointment> getThisWeek();

  List<Appointment> search(String query);

  int count();

  int countToday();

  // --- Yazma ---

  void add(Appointment appointment);

  /// Güncelleme — mock'ta henüz yok; remote Faz 2'de doldurulacak.
  bool update(Appointment appointment);
}
