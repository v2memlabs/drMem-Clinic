import '../models/sent_message.dart';

class SentMessageListLoadResult {
  final List<SentMessage> items;
  final String? errorMessage;

  const SentMessageListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory SentMessageListLoadResult.success(List<SentMessage> items) {
    return SentMessageListLoadResult._(items: items);
  }

  factory SentMessageListLoadResult.failure(String message) {
    return SentMessageListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
