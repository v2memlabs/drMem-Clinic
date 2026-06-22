import '../models/sent_message.dart';
import 'sent_message_list_load_result.dart';
import 'sent_message_repository_failure.dart';
import 'sent_message_repository_provider.dart';
import 'sent_message_user_messages.dart';

abstract final class SentMessageListDataSource {
  static Future<SentMessageListLoadResult> load({
    String? patientId,
    String? query,
    String? channelFilter,
    SendStatus? statusEnumFilter,
    String? categoryFilter,
  }) async {
    try {
      final items = await SentMessageRepositoryProvider.asyncRepository
          .getFiltered(
        patientId: patientId,
        query: query,
        channelFilter: channelFilter,
        statusEnumFilter: statusEnumFilter,
        categoryFilter: categoryFilter,
      );
      return SentMessageListLoadResult.success(items);
    } on SentMessageRepositoryException catch (e) {
      return SentMessageListLoadResult.failure(
        SentMessageUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return SentMessageListLoadResult.failure(
        SentMessageUserMessages.genericLoadFailure,
      );
    }
  }
}
