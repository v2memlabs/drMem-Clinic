import 'package:postgrest/postgrest.dart';

import 'message_template_repository_failure.dart';

abstract final class MessageTemplateRepositoryErrorMapper {
  static MessageTemplateRepositoryException toException(Object error) {
    if (error is MessageTemplateRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const MessageTemplateRepositoryException(
          MessageTemplateRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const MessageTemplateRepositoryException(
          MessageTemplateRepositoryFailure.notFound,
        );
      }
      return const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.notConfigured,
      );
    }
    return const MessageTemplateRepositoryException(
      MessageTemplateRepositoryFailure.unknown,
    );
  }

  static bool _isPermissionDenied(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501') return true;
    final msg = e.message.toLowerCase();
    return msg.contains('permission') ||
        msg.contains('forbidden') ||
        msg.contains('row-level security');
  }
}
