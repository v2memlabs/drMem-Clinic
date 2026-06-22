import '../models/message_template.dart';
import 'async_message_template_repository_contract.dart';
import 'message_repository.dart';

class MockAsyncMessageTemplateRepositoryAdapter
    implements AsyncMessageTemplateRepositoryContract {
  MessageRepository get _sync => MessageRepository.instance;

  @override
  Future<List<MessageTemplate>> getAll() async => _sync.getTemplates();

  @override
  Future<MessageTemplate?> getById(String id) async => _sync.getTemplateById(id);

  @override
  Future<List<MessageTemplate>> getFiltered({
    String? query,
    String? channelFilter,
    String? categoryFilter,
    Channel? channelEnumFilter,
    Category? categoryEnumFilter,
    bool activeOnly = false,
  }) async {
    return _sync.getFilteredTemplates(
      query: query,
      channelFilter: channelFilter,
      categoryFilter: categoryFilter,
      channelEnumFilter: channelEnumFilter,
      categoryEnumFilter: categoryEnumFilter,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<List<MessageTemplate>> search(String query) async =>
      _sync.searchTemplates(query);
}
