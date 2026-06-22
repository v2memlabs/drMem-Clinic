import '../models/message_template.dart';

class MessageTemplateListLoadResult {
  final List<MessageTemplate> items;
  final String? errorMessage;

  const MessageTemplateListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory MessageTemplateListLoadResult.success(List<MessageTemplate> items) {
    return MessageTemplateListLoadResult._(items: items);
  }

  factory MessageTemplateListLoadResult.failure(String message) {
    return MessageTemplateListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
