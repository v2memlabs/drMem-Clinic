import '../../../core/data/repository_registry.dart';
import '../models/post_op_protocol.dart';

/// Post-op protokol okuma — [RepositoryRegistry.postOpProtocolsAsync].
abstract final class PostOpProtocolLookupDataSource {
  static Future<PostOpProtocol?> findById(String protocolId) async {
    final id = protocolId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.postOpProtocolsAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<PostOpProtocol>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.postOpProtocolsAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
