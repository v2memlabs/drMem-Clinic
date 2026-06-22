import 'physiotherapy_session_repository_failure.dart';

abstract final class PhysiotherapySessionRepositoryErrorMapper {
  static PhysiotherapySessionRepositoryException toException(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.notConfigured,
      );
    }
    if (message.contains('violates') ||
        message.contains('23503') ||
        message.contains('23514')) {
      return const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.validation,
      );
    }
    return const PhysiotherapySessionRepositoryException(
      PhysiotherapySessionRepositoryFailure.unknown,
    );
  }
}
