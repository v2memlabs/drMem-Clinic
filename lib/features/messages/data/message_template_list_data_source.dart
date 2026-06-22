import '../models/message_template.dart';
import 'message_template_list_load_result.dart';
import 'message_template_repository_failure.dart';
import 'message_template_repository_provider.dart';
import 'message_template_user_messages.dart';

abstract final class MessageTemplateListDataSource {
  static Future<MessageTemplateListLoadResult> load({
    String? query,
    Channel? channelEnumFilter,
    Category? categoryEnumFilter,
    bool activeOnly = false,
  }) async {
    try {
      final items =
          await MessageTemplateRepositoryProvider.asyncRepository.getFiltered(
        query: query,
        channelEnumFilter: channelEnumFilter,
        categoryEnumFilter: categoryEnumFilter,
        activeOnly: activeOnly,
      );
      return MessageTemplateListLoadResult.success(items);
    } on MessageTemplateRepositoryException catch (e) {
      return MessageTemplateListLoadResult.failure(
        MessageTemplateUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return MessageTemplateListLoadResult.failure(
        MessageTemplateUserMessages.genericLoadFailure,
      );
    }
  }
}
