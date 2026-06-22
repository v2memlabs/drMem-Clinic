import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_list_filters.dart';
import 'physiotherapy_repository.dart';

/// Mock sync repository → async contract (referrals only).
class MockAsyncPhysiotherapyReferralRepositoryAdapter
    implements AsyncPhysiotherapyReferralRepositoryContract {
  PhysiotherapyRepository get _sync => PhysiotherapyRepository.instance;

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => _sync.getReferrals();

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      _sync.getReferralsByPatientId(patientId);

  @override
  Future<PhysiotherapyReferral?> getById(String id) async =>
      _sync.getReferralById(id);

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async =>
      _sync.searchReferrals(query);

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async {
    return _sync.getFilteredReferrals(
      patientId: patientId,
      query: query,
      statusEnumFilter: statusEnumFilter,
      physiotherapistFilter: physiotherapistFilter,
    );
  }

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async {
    _sync.addReferral(referral);
    return referral;
  }

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async {
    return _sync.updateReferralSafe(id, update);
  }
}
