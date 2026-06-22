import '../../../core/data/repository_registry.dart';
import '../models/prescription.dart';

abstract final class PrescriptionLookupDataSource {
  static Future<Prescription?> findById(String prescriptionId) async {
    final id = prescriptionId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.prescriptionsAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Prescription>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.prescriptionsAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
