import '../../patient_tags/data/mock_patient_tags.dart';
import '../../settings/data/mock_tenant_settings_repository.dart';
import '../models/patient.dart';
import 'mock_patients.dart';
import 'patient_access_filter.dart';
import 'patient_file_number_helper.dart';
import 'patient_repository_contract.dart';

// TODO(saas-migration): UI → [PatientRepositoryProvider.current] veya .instance (contract).

class PatientRepository implements PatientRepositoryContract {

  PatientRepository._();



  static final PatientRepository instance = PatientRepository._();



  @override
  List<Patient> getAll() =>
      List.unmodifiable(PatientAccessFilter.filterVisible(mockPatients));

  @override
  int count() => mockPatients.length;

  @override
  Patient? getById(String id) {

    for (final p in mockPatients) {

      if (p.id == id) {
        return PatientAccessFilter.canViewPatient(p) ? p : null;
      }

    }

    return null;

  }



  @override
  String getNameById(String id) => getById(id)?.fullName ?? 'Bilinmeyen Hasta';

  @override
  String nextFileNumber() {
    return PatientFileNumberHelper.nextFromExisting(
      mockPatients.map((p) => p.fileNumber),
      settings: MockTenantSettingsRepository.patientRegistrationSettings,
    );
  }



  @override
  void add(Patient patient) => mockPatients.add(patient);

  @override
  bool update(Patient updatedPatient) {
    final index = mockPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (index < 0) return false;
    mockPatients[index] = updatedPatient;
    return true;
  }



  @override
  void addTagToPatient({required String patientId, required String tagId}) {

    final index = mockPatients.indexWhere((p) => p.id == patientId);

    if (index < 0) return;

    final patient = mockPatients[index];

    if (patient.tagIds.contains(tagId)) return;

    mockPatients[index] = patient.copyWith(tagIds: [...patient.tagIds, tagId]);

    // TODO(audit): patient_tag.assigned

  }



  @override
  void removeTagFromPatient({required String patientId, required String tagId}) {

    final index = mockPatients.indexWhere((p) => p.id == patientId);

    if (index < 0) return;

    final patient = mockPatients[index];

    if (!patient.tagIds.contains(tagId)) return;

    mockPatients[index] = patient.copyWith(

      tagIds: patient.tagIds.where((id) => id != tagId).toList(),

    );

    // TODO(audit): patient_tag.removed

  }



  @override
  void updatePatientTags({required String patientId, required List<String> tagIds}) {

    final index = mockPatients.indexWhere((p) => p.id == patientId);

    if (index < 0) return;

    final unique = tagIds.toSet().toList();

    mockPatients[index] = mockPatients[index].copyWith(tagIds: unique);

  }



  @override
  int countPatientsWithTag(String tagId) {

    var count = 0;

    for (final p in mockPatients) {

      if (p.tagIds.contains(tagId)) count++;

    }

    return count;

  }



  @override
  List<Patient> search(String query) {

    final q = query.trim().toLowerCase();

    if (q.isEmpty) return getAll();

    return PatientAccessFilter.filterVisible(
      mockPatients.where((p) {

      if (p.firstName.toLowerCase().contains(q)) return true;

      if (p.lastName.toLowerCase().contains(q)) return true;

      if (p.fileNumber.toLowerCase().contains(q)) return true;

      if (p.phone.toLowerCase().contains(q)) return true;

      if (p.primaryComplaint.toLowerCase().contains(q)) return true;

      if (p.bodyRegion.toLowerCase().contains(q)) return true;

      if (p.tags.any((t) => t.toLowerCase().contains(q))) return true;

      for (final tagId in p.tagIds) {
        for (final tag in mockPatientTagDefinitions) {
          if (tag.id == tagId && tag.name.toLowerCase().contains(q)) {
            return true;
          }
        }
      }

      if (p.identityNumber.toLowerCase().contains(q)) return true;

      if (p.identityType.toLowerCase().contains(q)) return true;

      if (p.nationality.toLowerCase().contains(q)) return true;

      if (p.insuranceType.toLowerCase().contains(q)) return true;

      if (p.insuranceCompany.toLowerCase().contains(q)) return true;

      if (p.policyNumber.toLowerCase().contains(q)) return true;

      return false;

    }).toList(),
    );

  }

}


