import 'package:postgrest/postgrest.dart';

import 'clinical_encounter_repository_failure.dart';

/// Supabase/PostgREST hatalarını [ClinicalEncounterRepositoryException]'a çevirir.
abstract final class ClinicalEncounterRepositoryErrorMapper {
  static ClinicalEncounterRepositoryException toException(Object error) {
    if (error is ClinicalEncounterRepositoryException) return error;

    if (error is PostgrestException) {
      if (error.code == '23503') {
        return ClinicalEncounterRepositoryException(
          _mapForeignKeyViolation(error),
          cause: error,
        );
      }

      final mapped =
          ClinicalEncounterRepositoryFailureMessage.fromPostgresCode(
        error.code,
      );
      if (mapped != null) {
        return ClinicalEncounterRepositoryException(mapped, cause: error);
      }
      if (_isPermissionDenied(error)) {
        return ClinicalEncounterRepositoryException(
          ClinicalEncounterRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == 'PGRST116') {
        return ClinicalEncounterRepositoryException(
          ClinicalEncounterRepositoryFailure.notFound,
          cause: error,
        );
      }
      return ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.network,
        cause: error,
      );
    }

    return ClinicalEncounterRepositoryException(
      ClinicalEncounterRepositoryFailure.unknown,
      cause: error,
    );
  }

  static ClinicalEncounterRepositoryFailure _mapForeignKeyViolation(
    PostgrestException error,
  ) {
    final context = _errorContext(error);
    if (context.contains('appointment_id') || context.contains('appointments')) {
      return ClinicalEncounterRepositoryFailure.appointmentNotFound;
    }
    return ClinicalEncounterRepositoryFailure.patientNotFound;
  }

  static String _errorContext(PostgrestException error) {
    return '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
        .toLowerCase();
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
