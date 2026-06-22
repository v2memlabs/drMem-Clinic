import '../models/patient.dart';
import 'patient_repository.dart';
import 'patient_repository_contract.dart';

/// Mock implementasyon — [PatientRepository.instance] delegasyonu.
///
/// Tenant: mock'ta [TenantRepositoryScope.activeTenantId] ile aynı veri kümesi.
class MockPatientRepositoryAdapter implements PatientRepositoryContract {
  PatientRepository get _delegate => PatientRepository.instance;

  @override
  List<Patient> getAll() => _delegate.getAll();

  @override
  List<Patient> search(String query) => _delegate.search(query);

  @override
  Patient? getById(String id) => _delegate.getById(id);

  @override
  String getNameById(String id) => _delegate.getNameById(id);

  @override
  int count() => _delegate.count();

  @override
  String nextFileNumber() => _delegate.nextFileNumber();

  @override
  void add(Patient patient) => _delegate.add(patient);

  @override
  bool update(Patient updatedPatient) => _delegate.update(updatedPatient);

  @override
  void addTagToPatient({required String patientId, required String tagId}) {
    _delegate.addTagToPatient(patientId: patientId, tagId: tagId);
  }

  @override
  void removeTagFromPatient({required String patientId, required String tagId}) {
    _delegate.removeTagFromPatient(patientId: patientId, tagId: tagId);
  }

  @override
  void updatePatientTags({required String patientId, required List<String> tagIds}) {
    _delegate.updatePatientTags(patientId: patientId, tagIds: tagIds);
  }

  @override
  int countPatientsWithTag(String tagId) => _delegate.countPatientsWithTag(tagId);
}
