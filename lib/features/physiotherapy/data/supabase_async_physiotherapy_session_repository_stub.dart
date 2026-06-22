import '../models/physiotherapy_session_note.dart';
import 'async_physiotherapy_session_repository_contract.dart';
import 'physiotherapy_session_repository_failure.dart';

/// FTR seans notu — remote gate kapalıyken güvenli notConfigured.
class SupabaseAsyncPhysiotherapySessionRepositoryStub
    implements AsyncPhysiotherapySessionRepositoryContract {
  const SupabaseAsyncPhysiotherapySessionRepositoryStub();

  static Never _notReady() {
    throw const PhysiotherapySessionRepositoryException(
      PhysiotherapySessionRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<PhysiotherapySessionNote>> getAll() async => _notReady();

  @override
  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId) async =>
      _notReady();

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(String referralId) async =>
      _notReady();

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async => _notReady();

  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async =>
      _notReady();
}
