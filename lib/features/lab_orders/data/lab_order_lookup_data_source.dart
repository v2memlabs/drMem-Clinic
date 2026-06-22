import '../../../core/data/repository_registry.dart';
import '../models/lab_order.dart';

abstract final class LabOrderLookupDataSource {
  static Future<LabOrder?> findById(String labOrderId) async {
    final id = labOrderId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.labOrdersAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<LabOrder>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.labOrdersAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
