import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_repository_failure.dart';

/// FTR yönlendirme — remote gate kapalıyken güvenli notConfigured.
class SupabaseAsyncPhysiotherapyReferralRepositoryStub
    implements AsyncPhysiotherapyReferralRepositoryContract {
  const SupabaseAsyncPhysiotherapyReferralRepositoryStub();

  static Never _notReady() {
    throw const PhysiotherapyReferralRepositoryException(
      PhysiotherapyReferralRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => _notReady();

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      _notReady();

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => _notReady();

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => _notReady();

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      _notReady();

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      _notReady();

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      _notReady();
}
