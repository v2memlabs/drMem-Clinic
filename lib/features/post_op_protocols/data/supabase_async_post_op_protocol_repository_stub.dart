import '../models/post_op_protocol.dart';
import 'async_post_op_protocol_repository_contract.dart';
import 'post_op_protocol_repository_failure.dart';

class SupabaseAsyncPostOpProtocolRepositoryStub
    implements AsyncPostOpProtocolRepositoryContract {
  const SupabaseAsyncPostOpProtocolRepositoryStub();

  static const _error = PostOpProtocolRepositoryException(
    PostOpProtocolRepositoryFailure.notConfigured,
  );

  @override
  Future<PostOpProtocol> create(PostOpProtocol protocol) async => throw _error;

  @override
  Future<List<PostOpProtocol>> getAll() async => throw _error;

  @override
  Future<PostOpProtocol?> getById(String id) async => throw _error;

  @override
  Future<List<PostOpProtocol>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<PostOpProtocol>> getBySurgeryNoteId(String surgeryNoteId) async =>
      throw _error;

  @override
  Future<List<PostOpProtocol>> getFiltered({
    String? patientId,
    String? surgeryNoteId,
    String? query,
    PostOpPhase? phaseFilter,
    PostOpProtocolStatus? statusFilter,
  }) async =>
      throw _error;

  @override
  Future<List<PostOpProtocol>> search(String query) async => throw _error;
}
