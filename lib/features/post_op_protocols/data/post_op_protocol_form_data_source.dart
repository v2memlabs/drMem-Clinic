import '../models/post_op_protocol.dart';
import 'post_op_protocol_list_refresh.dart';
import 'post_op_protocol_repository_failure.dart';
import 'post_op_protocol_repository_provider.dart';
import 'post_op_protocol_user_messages.dart';

abstract final class PostOpProtocolFormDataSource {
  static Future<PostOpProtocol> create(PostOpProtocol draft) async {
    try {
      final saved =
          await PostOpProtocolRepositoryProvider.asyncRepository.create(
        draft,
      );
      PostOpProtocolListRefresh.markStale();
      return saved;
    } on PostOpProtocolRepositoryException catch (e) {
      throw PostOpProtocolFormException(
        PostOpProtocolUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const PostOpProtocolFormException(
        PostOpProtocolUserMessages.genericSaveFailure,
      );
    }
  }
}

class PostOpProtocolFormException implements Exception {
  final String message;

  const PostOpProtocolFormException(this.message);

  @override
  String toString() => message;
}
