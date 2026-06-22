import '../../../core/data/repository_registry.dart';
import '../models/patient.dart';
import 'patient_repository_failure.dart';

/// Hasta form — async create/update/load ([RepositoryRegistry.patientsAsync]).
abstract final class PatientFormDataSource {
  static Future<Patient?> loadForEdit(String id) async {
    try {
      return await RepositoryRegistry.patientsAsync.getById(id);
    } on PatientRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientRepositoryException(PatientRepositoryFailure.unknown);
    }
  }

  static Future<String> nextFileNumber() async {
    try {
      return await RepositoryRegistry.patientsAsync.nextFileNumber();
    } on PatientRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientRepositoryException(PatientRepositoryFailure.unknown);
    }
  }

  static Future<Patient> create(Patient draft) async {
    final toAdd = _prepareCreateDraft(draft);
    try {
      return await RepositoryRegistry.patientsAsync.add(toAdd);
    } on PatientRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientRepositoryException(PatientRepositoryFailure.unknown);
    }
  }

  static Future<Patient> update(Patient patient) async {
    try {
      return await RepositoryRegistry.patientsAsync.update(patient);
    } on PatientRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientRepositoryException(PatientRepositoryFailure.unknown);
    }
  }

  static Patient _prepareCreateDraft(Patient draft) {
    if (RepositoryRegistry.usesRemotePatients) {
      return draft.copyWith(id: '');
    }
    if (draft.id.isEmpty) {
      return draft.copyWith(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    return draft;
  }
}
