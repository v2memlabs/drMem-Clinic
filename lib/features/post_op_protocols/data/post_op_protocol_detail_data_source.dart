import '../models/post_op_protocol.dart';
import 'post_op_protocol_repository_failure.dart';
import 'post_op_protocol_repository_provider.dart';
import 'post_op_protocol_user_messages.dart';

class PostOpProtocolDetailLoadResult {
  final PostOpProtocol? protocol;
  final String? errorMessage;

  const PostOpProtocolDetailLoadResult._({this.protocol, this.errorMessage});

  factory PostOpProtocolDetailLoadResult.success(PostOpProtocol protocol) {
    return PostOpProtocolDetailLoadResult._(protocol: protocol);
  }

  factory PostOpProtocolDetailLoadResult.failure(String message) {
    return PostOpProtocolDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PostOpProtocolDetailDataSource {
  static Future<PostOpProtocolDetailLoadResult> load(String id) async {
    try {
      final protocol =
          await PostOpProtocolRepositoryProvider.asyncRepository.getById(id);
      if (protocol == null) {
        return PostOpProtocolDetailLoadResult.failure(
          PostOpProtocolUserMessages.notFound,
        );
      }
      return PostOpProtocolDetailLoadResult.success(protocol);
    } on PostOpProtocolRepositoryException catch (e) {
      return PostOpProtocolDetailLoadResult.failure(
        PostOpProtocolUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PostOpProtocolDetailLoadResult.failure(
        PostOpProtocolUserMessages.genericLoadFailure,
      );
    }
  }
}
