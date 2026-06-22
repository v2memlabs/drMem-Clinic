import '../models/sent_message.dart';
import 'sent_message_list_refresh.dart';
import 'sent_message_repository_failure.dart';
import 'sent_message_repository_provider.dart';
import 'sent_message_user_messages.dart';

abstract final class SentMessageFormDataSource {
  static Future<SentMessage> create(
    SentMessage draft, {
    String? templateId,
    String? patientEmail,
    String? fullContent,
  }) async {
    try {
      final saved = await SentMessageRepositoryProvider.asyncRepository.create(
        draft,
        templateId: templateId,
        patientEmail: patientEmail,
        fullContent: fullContent,
      );
      SentMessageListRefresh.markStale();
      return saved;
    } on SentMessageRepositoryException catch (e) {
      throw SentMessageFormException(
        SentMessageUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const SentMessageFormException(
        SentMessageUserMessages.genericSaveFailure,
      );
    }
  }
}

class SentMessageFormException implements Exception {
  final String message;

  const SentMessageFormException(this.message);

  @override
  String toString() => message;
}
