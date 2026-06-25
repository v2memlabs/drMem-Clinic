import '../models/message_template.dart';

abstract interface class AsyncMessageTemplateRepositoryContract {
  Future<List<MessageTemplate>> getAll();

  Future<MessageTemplate?> getById(String id);

  Future<List<MessageTemplate>> getFiltered({
    String? query,
    String? channelFilter,
    String? categoryFilter,
    Channel? channelEnumFilter,
    Category? categoryEnumFilter,
    bool activeOnly = false,
  });

  Future<List<MessageTemplate>> search(String query);

  Future<MessageTemplate> create(MessageTemplate template);

  Future<MessageTemplate> update(MessageTemplate template);
}
