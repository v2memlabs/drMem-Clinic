import 'package:postgrest/postgrest.dart';

import 'prescription_repository_failure.dart';

abstract final class PrescriptionRepositoryErrorMapper {
  static PrescriptionRepositoryException toException(Object error) {
    if (error is PrescriptionRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const PrescriptionRepositoryException(
          PrescriptionRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const PrescriptionRepositoryException(
          PrescriptionRepositoryFailure.notFound,
        );
      }
      return const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.notConfigured,
      );
    }
    return const PrescriptionRepositoryException(
      PrescriptionRepositoryFailure.unknown,
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
