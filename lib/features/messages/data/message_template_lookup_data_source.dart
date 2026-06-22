import '../../../core/data/repository_registry.dart';
import '../models/message_template.dart';

abstract final class MessageTemplateLookupDataSource {
  static Future<MessageTemplate?> findById(String templateId) async {
    final id = templateId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.messageTemplatesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<MessageTemplate>> listAll() async {
    try {
      return await RepositoryRegistry.messageTemplatesAsync.getAll();
    } catch (_) {
      return const [];
    }
  }
}
