import '../../../core/data/repository_registry.dart';
import '../models/clinical_encounter.dart';
import 'clinical_encounter_repository.dart';

/// Muayene okuma — mock sync veya remote async ([RepositoryRegistry.clinicalEncountersAsync]).
abstract final class ClinicalEncounterLookupDataSource {
  static Future<ClinicalEncounter?> findById(String encounterId) async {
    final id = encounterId.trim();
    if (id.isEmpty) return null;

    if (RepositoryRegistry.usesRemoteClinicalEncounters) {
      try {
        return await RepositoryRegistry.clinicalEncountersAsync.getById(id);
      } catch (_) {
        return null;
      }
    }

    return ClinicalEncounterRepository.instance.getById(id);
  }

  static Future<List<ClinicalEncounter>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    if (RepositoryRegistry.usesRemoteClinicalEncounters) {
      try {
        return await RepositoryRegistry.clinicalEncountersAsync.getByPatientId(pid);
      } catch (_) {
        return const [];
      }
    }

    return ClinicalEncounterRepository.instance.getByPatientId(pid);
  }

  static Future<bool> exists(String encounterId) async {
    final encounter = await findById(encounterId);
    return encounter != null;
  }

  /// Mock-only modüller için senkron okuma.
  static ClinicalEncounter? findByIdSync(String encounterId) {
    final id = encounterId.trim();
    if (id.isEmpty) return null;
    return ClinicalEncounterRepository.instance.getById(id);
  }
}
