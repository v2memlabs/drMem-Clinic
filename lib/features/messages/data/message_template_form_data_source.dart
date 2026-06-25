import '../models/message_template.dart';
import 'message_template_list_refresh.dart';
import 'message_template_repository_failure.dart';
import 'message_template_repository_provider.dart';
import 'message_template_user_messages.dart';

class MessageTemplateFormException implements Exception {
  final String message;

  const MessageTemplateFormException(this.message);

  @override
  String toString() => message;
}

abstract final class MessageTemplateFormDataSource {
  static Future<MessageTemplate> save({
    required MessageTemplate draft,
    required bool isEdit,
  }) async {
    try {
      final repo = MessageTemplateRepositoryProvider.asyncRepository;
      final saved = isEdit ? await repo.update(draft) : await repo.create(draft);
      MessageTemplateListRefresh.markStale();
      return saved;
    } on MessageTemplateRepositoryException catch (e) {
      throw MessageTemplateFormException(
        MessageTemplateUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const MessageTemplateFormException(
        MessageTemplateUserMessages.genericSaveFailure,
      );
    }
  }
}
