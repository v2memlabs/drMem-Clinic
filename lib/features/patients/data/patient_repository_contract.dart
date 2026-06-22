import '../models/patient.dart';

/// Hasta veri erişim sözleşmesi — mock ve Supabase implementasyonları.
///
/// Tenant izolasyonu: implementasyonlar [TenantRepositoryScope.activeTenantId]
/// ile filtreler (remote Faz 2). UI'dan `tenant_id` parametresi geçirilmez.
abstract interface class PatientRepositoryContract {
  // --- Okuma ---

  /// Tüm hastalar (aktif tenant kapsamında).
  List<Patient> getAll();

  /// Arama / filtre — mevcut liste ekranı mantığı.
  List<Patient> search(String query);

  /// Tekil hasta.
  Patient? getById(String id);

  String getNameById(String id);

  /// Demo limit ve özet kartlar için kayıt sayısı.
  int count();

  // --- Yazma ---

  /// Yeni dosya numarası üretimi (tenant bazlı sequence Faz 2).
  String nextFileNumber();

  void add(Patient patient);

  bool update(Patient updatedPatient);

  // --- Etiket ilişkileri (mevcut mock) ---

  void addTagToPatient({required String patientId, required String tagId});

  void removeTagFromPatient({required String patientId, required String tagId});

  void updatePatientTags({required String patientId, required List<String> tagIds});

  int countPatientsWithTag(String tagId);
}
