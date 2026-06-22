import 'package:postgrest/postgrest.dart';

import 'radiology_order_repository_failure.dart';

abstract final class RadiologyOrderRepositoryErrorMapper {
  static RadiologyOrderRepositoryException toException(Object error) {
    if (error is RadiologyOrderRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const RadiologyOrderRepositoryException(
          RadiologyOrderRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const RadiologyOrderRepositoryException(
          RadiologyOrderRepositoryFailure.notFound,
        );
      }
      return const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.notConfigured,
      );
    }
    return const RadiologyOrderRepositoryException(
      RadiologyOrderRepositoryFailure.unknown,
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
