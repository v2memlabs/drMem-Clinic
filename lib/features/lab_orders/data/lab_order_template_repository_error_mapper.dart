import 'package:postgrest/postgrest.dart';

import 'lab_order_template_repository_failure.dart';

abstract final class LabOrderTemplateRepositoryErrorMapper {
  static LabOrderTemplateRepositoryException toException(Object error) {
    if (error is LabOrderTemplateRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const LabOrderTemplateRepositoryException(
          LabOrderTemplateRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const LabOrderTemplateRepositoryException(
          LabOrderTemplateRepositoryFailure.notFound,
        );
      }
      return const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.notConfigured,
      );
    }
    return const LabOrderTemplateRepositoryException(
      LabOrderTemplateRepositoryFailure.unknown,
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
