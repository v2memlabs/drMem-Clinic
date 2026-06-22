import '../models/physiotherapy_session_note.dart';
import 'async_physiotherapy_session_repository_contract.dart';
import 'physiotherapy_repository.dart';

/// Mock sync repository → async contract (session notes only).
class MockAsyncPhysiotherapySessionRepositoryAdapter
    implements AsyncPhysiotherapySessionRepositoryContract {
  PhysiotherapyRepository get _sync => PhysiotherapyRepository.instance;

  @override
  Future<List<PhysiotherapySessionNote>> getAll() async =>
      _sync.getSessionNotes();

  @override
  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId) async =>
      _sync.getSessionNotesByPatientId(patientId);

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(
    String referralId,
  ) async =>
      _sync.getSessionNotesByReferralId(referralId);

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async =>
      _sync.getSessionNoteById(id);

  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async {
    _sync.addSessionNote(session);
    return session;
  }
}
