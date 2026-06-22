import '../models/sent_message.dart';
import 'sent_message_repository_failure.dart';
import 'sent_message_repository_provider.dart';
import 'sent_message_user_messages.dart';

class SentMessageDetailLoadResult {
  final SentMessage? message;
  final String? errorMessage;

  const SentMessageDetailLoadResult._({
    this.message,
    this.errorMessage,
  });

  factory SentMessageDetailLoadResult.success(SentMessage message) {
    return SentMessageDetailLoadResult._(message: message);
  }

  factory SentMessageDetailLoadResult.failure(String message) {
    return SentMessageDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class SentMessageDetailDataSource {
  static Future<SentMessageDetailLoadResult> load(String id) async {
    try {
      final message =
          await SentMessageRepositoryProvider.asyncRepository.getById(id);
      if (message == null) {
        return SentMessageDetailLoadResult.failure(
          SentMessageUserMessages.notFound,
        );
      }
      return SentMessageDetailLoadResult.success(message);
    } on SentMessageRepositoryException catch (e) {
      return SentMessageDetailLoadResult.failure(
        SentMessageUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return SentMessageDetailLoadResult.failure(
        SentMessageUserMessages.genericLoadFailure,
      );
    }
  }
}
