import 'package:postgrest/postgrest.dart';

import 'timeline_repository_failure.dart';

/// Supabase/PostgREST → [TimelineRepositoryException].
abstract final class TimelineRepositoryErrorMapper {
  static TimelineRepositoryException toException(Object error) {
    if (error is TimelineRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return TimelineRepositoryException(
          TimelineRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == 'PGRST116') {
        return TimelineRepositoryException(
          TimelineRepositoryFailure.notFound,
          cause: error,
        );
      }
      return TimelineRepositoryException(
        TimelineRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return TimelineRepositoryException(
        TimelineRepositoryFailure.network,
        cause: error,
      );
    }

    return TimelineRepositoryException(
      TimelineRepositoryFailure.unknown,
      cause: error,
    );
  }

  static bool _isPermissionDenied(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501') return true;
    final msg = e.message.toLowerCase();
    return msg.contains('permission') ||
        msg.contains('row-level security') ||
        msg.contains('rls');
  }

  static bool _isNetworkError(Object error) {
    final type = error.runtimeType.toString().toLowerCase();
    return type.contains('socket') ||
        type.contains('timeout') ||
        type.contains('clientexception');
  }
}
