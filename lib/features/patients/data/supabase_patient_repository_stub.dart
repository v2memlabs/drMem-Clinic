import '../models/patient.dart';
import 'patient_repository_contract.dart';

/// Supabase hasta repository — pasif iskelet (Faz 2+).
///
/// [PatientRepositoryProvider] bu sınıfı çağırmaz; runtime hatası üretmez.
class SupabasePatientRepositoryStub implements PatientRepositoryContract {
  const SupabasePatientRepositoryStub();

  @override
  List<Patient> getAll() => const [];

  @override
  List<Patient> search(String query) => const [];

  @override
  Patient? getById(String id) => null;

  @override
  String getNameById(String id) => 'Bilinmeyen Hasta';

  @override
  int count() => 0;

  @override
  String nextFileNumber() => 'H-2026-0000';

  @override
  void add(Patient patient) {}

  @override
  bool update(Patient updatedPatient) => false;

  @override
  void addTagToPatient({required String patientId, required String tagId}) {}

  @override
  void removeTagFromPatient({required String patientId, required String tagId}) {}

  @override
  void updatePatientTags({required String patientId, required List<String> tagIds}) {}

  @override
  int countPatientsWithTag(String tagId) => 0;
}
