import '../../../core/data/repository_registry.dart';
import '../models/sent_message.dart';

abstract final class SentMessageLookupDataSource {
  static Future<SentMessage?> findById(String messageId) async {
    final id = messageId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.sentMessagesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<SentMessage>> listByPatientId(String patientId) async {
    final id = patientId.trim();
    if (id.isEmpty) return const [];

    try {
      return await RepositoryRegistry.sentMessagesAsync.getByPatientId(id);
    } catch (_) {
      return const [];
    }
  }
}
