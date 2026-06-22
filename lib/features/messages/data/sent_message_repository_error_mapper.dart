import 'package:postgrest/postgrest.dart';

import 'sent_message_repository_failure.dart';

abstract final class SentMessageRepositoryErrorMapper {
  static SentMessageRepositoryException toException(Object error) {
    if (error is SentMessageRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const SentMessageRepositoryException(
          SentMessageRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const SentMessageRepositoryException(
          SentMessageRepositoryFailure.notFound,
        );
      }
      return const SentMessageRepositoryException(
        SentMessageRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const SentMessageRepositoryException(
        SentMessageRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const SentMessageRepositoryException(
        SentMessageRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const SentMessageRepositoryException(
        SentMessageRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const SentMessageRepositoryException(
        SentMessageRepositoryFailure.notConfigured,
      );
    }
    return const SentMessageRepositoryException(
      SentMessageRepositoryFailure.unknown,
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
