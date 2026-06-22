import 'package:postgrest/postgrest.dart';

import 'patient_repository_failure.dart';

/// Supabase/PostgREST hatalarını [PatientRepositoryException]'a çevirir.
abstract final class PatientRepositoryErrorMapper {
  static PatientRepositoryException toException(Object error) {
    if (error is PatientRepositoryException) return error;

    if (error is PostgrestException) {
      final mapped = PatientRepositoryFailureMessage.fromPostgresCode(error.code);
      if (mapped != null) {
        return PatientRepositoryException(mapped, cause: error);
      }
      if (_isPermissionDenied(error)) {
        return PatientRepositoryException(
          PatientRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == 'PGRST116') {
        return PatientRepositoryException(
          PatientRepositoryFailure.notFound,
          cause: error,
        );
      }
      return PatientRepositoryException(
        PatientRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return PatientRepositoryException(
        PatientRepositoryFailure.network,
        cause: error,
      );
    }

    return PatientRepositoryException(
      PatientRepositoryFailure.unknown,
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
