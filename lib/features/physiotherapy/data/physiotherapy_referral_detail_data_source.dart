import '../../../core/data/repository_registry.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_detail_load_result.dart';
import 'physiotherapy_referral_list_refresh.dart';
import 'physiotherapy_referral_repository_failure.dart';
import 'physiotherapy_referral_user_messages.dart';

abstract final class PhysiotherapyReferralDetailDataSource {
  static Future<PhysiotherapyReferralDetailLoadResult> load(String id) async {
    try {
      final referral =
          await RepositoryRegistry.physiotherapyReferralsAsync.getById(id);
      if (referral == null) {
        return PhysiotherapyReferralDetailLoadResult.notFound();
      }
      return PhysiotherapyReferralDetailLoadResult.success(referral);
    } on PhysiotherapyReferralRepositoryException catch (e) {
      return PhysiotherapyReferralDetailLoadResult.failure(
        PhysiotherapyReferralDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PhysiotherapyReferralDetailLoadResult.failure(
        PhysiotherapyReferralListUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<String?> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async {
    try {
      await RepositoryRegistry.physiotherapyReferralsAsync.updateSafeFields(
        id,
        update,
      );
      PhysiotherapyReferralListRefresh.markStale();
      return null;
    } on PhysiotherapyReferralRepositoryException catch (e) {
      return PhysiotherapyReferralDetailUserMessages.forFailure(e.reason);
    } catch (_) {
      return PhysiotherapyReferralDetailUserMessages.saveFailure;
    }
  }
}
