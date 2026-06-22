import '../models/message_template.dart';
import 'async_message_template_repository_contract.dart';
import 'message_template_repository_failure.dart';

class SupabaseAsyncMessageTemplateRepositoryStub
    implements AsyncMessageTemplateRepositoryContract {
  const SupabaseAsyncMessageTemplateRepositoryStub();

  static const _error = MessageTemplateRepositoryException(
    MessageTemplateRepositoryFailure.notConfigured,
  );

  @override
  Future<List<MessageTemplate>> getAll() async => throw _error;

  @override
  Future<MessageTemplate?> getById(String id) async => throw _error;

  @override
  Future<List<MessageTemplate>> getFiltered({
    String? query,
    String? channelFilter,
    String? categoryFilter,
    Channel? channelEnumFilter,
    Category? categoryEnumFilter,
    bool activeOnly = false,
  }) async =>
      throw _error;

  @override
  Future<List<MessageTemplate>> search(String query) async => throw _error;
}
