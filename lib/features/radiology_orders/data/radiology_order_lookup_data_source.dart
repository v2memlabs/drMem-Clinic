import '../../../core/data/repository_registry.dart';
import '../models/radiology_order.dart';

abstract final class RadiologyOrderLookupDataSource {
  static Future<RadiologyOrder?> findById(String orderId) async {
    final id = orderId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.radiologyOrdersAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<RadiologyOrder>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.radiologyOrdersAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
