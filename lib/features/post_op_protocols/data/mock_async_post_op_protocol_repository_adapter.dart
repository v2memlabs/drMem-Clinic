import '../models/post_op_protocol.dart';
import 'async_post_op_protocol_repository_contract.dart';
import 'post_op_protocol_repository.dart';

class MockAsyncPostOpProtocolRepositoryAdapter
    implements AsyncPostOpProtocolRepositoryContract {
  PostOpProtocolRepository get _sync => PostOpProtocolRepository.instance;

  @override
  Future<PostOpProtocol> create(PostOpProtocol protocol) async {
    _sync.add(protocol);
    return protocol;
  }

  @override
  Future<List<PostOpProtocol>> getAll() async => _sync.getAll();

  @override
  Future<PostOpProtocol?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<PostOpProtocol>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<PostOpProtocol>> getBySurgeryNoteId(String surgeryNoteId) async =>
      _sync.getBySurgeryNoteId(surgeryNoteId);

  @override
  Future<List<PostOpProtocol>> getFiltered({
    String? patientId,
    String? surgeryNoteId,
    String? query,
    PostOpPhase? phaseFilter,
    PostOpProtocolStatus? statusFilter,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      surgeryNoteId: surgeryNoteId,
      query: query,
      phaseFilter: phaseFilter,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<List<PostOpProtocol>> search(String query) async =>
      _sync.search(query);
}
