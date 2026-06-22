import 'package:postgrest/postgrest.dart';

import 'lab_order_repository_failure.dart';

abstract final class LabOrderRepositoryErrorMapper {
  static LabOrderRepositoryException toException(Object error) {
    if (error is LabOrderRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const LabOrderRepositoryException(
          LabOrderRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const LabOrderRepositoryException(
          LabOrderRepositoryFailure.notFound,
        );
      }
      return const LabOrderRepositoryException(
        LabOrderRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const LabOrderRepositoryException(
        LabOrderRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const LabOrderRepositoryException(
        LabOrderRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const LabOrderRepositoryException(
        LabOrderRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const LabOrderRepositoryException(
        LabOrderRepositoryFailure.notConfigured,
      );
    }
    return const LabOrderRepositoryException(
      LabOrderRepositoryFailure.unknown,
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
