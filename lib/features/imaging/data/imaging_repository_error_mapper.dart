import 'imaging_repository_failure.dart';

abstract final class ImagingRepositoryErrorMapper {
  static ImagingRepositoryException toException(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const ImagingRepositoryException(
        ImagingRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const ImagingRepositoryException(
        ImagingRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const ImagingRepositoryException(
        ImagingRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const ImagingRepositoryException(
        ImagingRepositoryFailure.notConfigured,
      );
    }
    return const ImagingRepositoryException(ImagingRepositoryFailure.unknown);
  }
}
