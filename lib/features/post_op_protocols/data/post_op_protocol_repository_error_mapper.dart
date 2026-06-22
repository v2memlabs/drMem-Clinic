import 'post_op_protocol_repository_failure.dart';

abstract final class PostOpProtocolRepositoryErrorMapper {
  static PostOpProtocolRepositoryException toException(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission') ||
        msg.contains('rls') ||
        msg.contains('42501')) {
      return const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.forbidden,
      );
    }
    if (msg.contains('not found') || msg.contains('pgrst116')) {
      return const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.notFound,
      );
    }
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.network,
      );
    }
    if (msg.contains('supabase') && msg.contains('configured')) {
      return const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.notConfigured,
      );
    }
    return const PostOpProtocolRepositoryException(
      PostOpProtocolRepositoryFailure.unknown,
    );
  }
}
