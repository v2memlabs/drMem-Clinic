import '../models/post_op_protocol.dart';
import 'post_op_protocol_repository_failure.dart';
import 'post_op_protocol_repository_provider.dart';
import 'post_op_protocol_user_messages.dart';

class PostOpProtocolListLoadResult {
  final List<PostOpProtocol> protocols;
  final String? errorMessage;

  const PostOpProtocolListLoadResult._({
    this.protocols = const [],
    this.errorMessage,
  });

  factory PostOpProtocolListLoadResult.success(List<PostOpProtocol> protocols) {
    return PostOpProtocolListLoadResult._(protocols: protocols);
  }

  factory PostOpProtocolListLoadResult.failure(String message) {
    return PostOpProtocolListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PostOpProtocolListDataSource {
  static Future<PostOpProtocolListLoadResult> load({
    String? patientId,
    String? surgeryNoteId,
    String? query,
    PostOpPhase? phaseFilter,
    PostOpProtocolStatus? statusFilter,
  }) async {
    try {
      final protocols =
          await PostOpProtocolRepositoryProvider.asyncRepository.getFiltered(
        patientId: patientId,
        surgeryNoteId: surgeryNoteId,
        query: query,
        phaseFilter: phaseFilter,
        statusFilter: statusFilter,
      );
      return PostOpProtocolListLoadResult.success(protocols);
    } on PostOpProtocolRepositoryException catch (e) {
      return PostOpProtocolListLoadResult.failure(
        PostOpProtocolUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PostOpProtocolListLoadResult.failure(
        PostOpProtocolUserMessages.genericLoadFailure,
      );
    }
  }
}
