import '../models/post_op_protocol.dart';

abstract interface class AsyncPostOpProtocolRepositoryContract {
  Future<List<PostOpProtocol>> getAll();

  Future<List<PostOpProtocol>> getByPatientId(String patientId);

  Future<List<PostOpProtocol>> getBySurgeryNoteId(String surgeryNoteId);

  Future<PostOpProtocol?> getById(String id);

  Future<List<PostOpProtocol>> search(String query);

  Future<List<PostOpProtocol>> getFiltered({
    String? patientId,
    String? surgeryNoteId,
    String? query,
    PostOpPhase? phaseFilter,
    PostOpProtocolStatus? statusFilter,
  });

  Future<PostOpProtocol> create(PostOpProtocol protocol);
}
