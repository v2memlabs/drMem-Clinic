import '../models/physiotherapy_session_note.dart';

/// Async FTR seans notu repository — liste/detay/form active backend hattı.
abstract interface class AsyncPhysiotherapySessionRepositoryContract {
  Future<List<PhysiotherapySessionNote>> getAll();

  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId);

  Future<List<PhysiotherapySessionNote>> getByReferralId(String referralId);

  Future<PhysiotherapySessionNote?> getById(String id);

  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session);
}
