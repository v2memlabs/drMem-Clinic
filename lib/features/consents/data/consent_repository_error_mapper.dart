import 'package:postgrest/postgrest.dart';

import '../../patient_files/data/patient_file_metadata_repository_failure.dart';
import 'consent_repository_failure.dart';

/// PostgREST / Supabase hatalarını güvenli [ConsentRepositoryException]'a çevirir.
abstract final class ConsentRepositoryErrorMapper {
  static ConsentRepositoryException toException(Object error) {
    if (error is ConsentRepositoryException) return error;

    if (error is PatientFileMetadataRepositoryException) {
      return const ConsentRepositoryException(
        ConsentRepositoryFailure.invalidRow,
      );
    }

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const ConsentRepositoryException(
          ConsentRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const ConsentRepositoryException(
          ConsentRepositoryFailure.notFound,
        );
      }
      return const ConsentRepositoryException(ConsentRepositoryFailure.unknown);
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const ConsentRepositoryException(
        ConsentRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const ConsentRepositoryException(
        ConsentRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const ConsentRepositoryException(
        ConsentRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const ConsentRepositoryException(
        ConsentRepositoryFailure.notConfigured,
      );
    }
    return const ConsentRepositoryException(ConsentRepositoryFailure.unknown);
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
