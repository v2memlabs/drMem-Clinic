import '../../../core/data/repository_registry.dart';
import 'physiotherapy_referral_lookup_load_result.dart';
import 'physiotherapy_referral_repository_failure.dart';

/// Session/exercise form ve detail için paylaşılan async yönlendirme lookup.
abstract final class PhysiotherapyReferralLookupDataSource {
  static Future<PhysiotherapyReferralLookupLoadResult> getById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return PhysiotherapyReferralLookupLoadResult.notFound();
    }

    try {
      final referral =
          await RepositoryRegistry.physiotherapyReferralsAsync.getById(trimmed);
      if (referral == null) {
        return PhysiotherapyReferralLookupLoadResult.notFound();
      }
      return PhysiotherapyReferralLookupLoadResult.found(referral);
    } on PhysiotherapyReferralRepositoryException catch (_) {
      return PhysiotherapyReferralLookupLoadResult.unavailable();
    } catch (_) {
      return PhysiotherapyReferralLookupLoadResult.unavailable();
    }
  }
}
