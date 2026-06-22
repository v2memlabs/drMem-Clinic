import '../../../core/data/repository_registry.dart';
import '../../patient_tags/data/patient_tag_repository_provider.dart';
import '../models/patient.dart';
import 'patient_repository.dart';

/// Hasta okuma — mock sync veya remote async ([RepositoryRegistry.patientsAsync]).
abstract final class PatientLookupDataSource {
  static Future<Patient?> findById(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;

    if (RepositoryRegistry.usesRemotePatients) {
      try {
        return await RepositoryRegistry.patientsAsync.getById(pid);
      } catch (_) {
        return null;
      }
    }

    return PatientRepository.instance.getById(pid);
  }

  static Future<bool> exists(String patientId) async {
    final patient = await findById(patientId);
    return patient != null;
  }

  static Future<String> resolveName({
    required String patientId,
    Patient? selectedPatient,
    String remoteFallback = 'Hasta',
    String mockFallback = 'Bilinmeyen',
  }) async {
    if (selectedPatient != null && selectedPatient.id == patientId) {
      return selectedPatient.fullName;
    }

    final patient = await findById(patientId);
    if (patient != null) return patient.fullName;

    return RepositoryRegistry.usesRemotePatients
        ? remoteFallback
        : mockFallback;
  }

  static Future<String?> resolveFileNumber(String patientId) async {
    final patient = await findById(patientId);
    final fileNumber = patient?.fileNumber.trim();
    if (fileNumber == null || fileNumber.isEmpty) return null;
    return fileNumber;
  }

  /// Mock-only modüller için senkron okuma (her zaman [PatientRepository.instance]).
  static Patient? findByIdSync(String patientId) {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;
    return PatientRepository.instance.getById(pid);
  }

  static int countPatientsWithTagSync(String tagId) {
    return PatientRepository.instance.countPatientsWithTag(tagId);
  }

  /// Mock: sync sayım; remote: [PatientTagRepositoryProvider] üzerinden async.
  static Future<int> countPatientsWithTag(String tagId) async {
    final tid = tagId.trim();
    if (tid.isEmpty) return 0;

    if (RepositoryRegistry.usesRemotePatients) {
      try {
        final repo = PatientTagRepositoryProvider.repository;
        if (PatientTagRepositoryProvider.usesRemote) {
          return await repo.countPatientsWithTag(tid);
        }
      } catch (_) {
        return 0;
      }
    }

    return countPatientsWithTagSync(tid);
  }
}
