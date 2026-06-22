import 'package:postgrest/postgrest.dart';

import 'patient_file_metadata_repository_failure.dart';

/// Supabase/PostgREST → [PatientFileMetadataRepositoryException].
abstract final class PatientFileMetadataRepositoryErrorMapper {
  static PatientFileMetadataRepositoryException toException(Object error) {
    if (error is PatientFileMetadataRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return PatientFileMetadataRepositoryException(
          PatientFileMetadataRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == 'PGRST116') {
        return PatientFileMetadataRepositoryException(
          PatientFileMetadataRepositoryFailure.notFound,
          cause: error,
        );
      }
      return PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.network,
        cause: error,
      );
    }

    return PatientFileMetadataRepositoryException(
      PatientFileMetadataRepositoryFailure.unknown,
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
