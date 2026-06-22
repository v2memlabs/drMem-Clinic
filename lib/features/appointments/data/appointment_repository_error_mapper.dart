import 'package:postgrest/postgrest.dart';

import 'appointment_repository_failure.dart';

/// Supabase/PostgREST hatalarını [AppointmentRepositoryException]'a çevirir.
abstract final class AppointmentRepositoryErrorMapper {
  static AppointmentRepositoryException toException(Object error) {
    if (error is AppointmentRepositoryException) return error;

    if (error is PostgrestException) {
      final mapped =
          AppointmentRepositoryFailureMessage.fromPostgresCode(error.code);
      if (mapped != null) {
        return AppointmentRepositoryException(mapped, cause: error);
      }
      if (_isPermissionDenied(error)) {
        return AppointmentRepositoryException(
          AppointmentRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == 'PGRST116') {
        return AppointmentRepositoryException(
          AppointmentRepositoryFailure.notFound,
          cause: error,
        );
      }
      return AppointmentRepositoryException(
        AppointmentRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return AppointmentRepositoryException(
        AppointmentRepositoryFailure.network,
        cause: error,
      );
    }

    return AppointmentRepositoryException(
      AppointmentRepositoryFailure.unknown,
      cause: error,
    );
  }

  static bool _isPermissionDenied(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501') return true;
    final msg = (e.message).toLowerCase();
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
