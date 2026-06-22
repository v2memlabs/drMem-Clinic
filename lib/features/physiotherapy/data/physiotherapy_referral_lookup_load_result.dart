import '../models/physiotherapy_referral.dart';

/// Async yönlendirme lookup sonucu — session/exercise continuity köprüsü.
class PhysiotherapyReferralLookupLoadResult {
  final PhysiotherapyReferral? referral;

  const PhysiotherapyReferralLookupLoadResult._({this.referral});

  factory PhysiotherapyReferralLookupLoadResult.found(
    PhysiotherapyReferral referral,
  ) {
    return PhysiotherapyReferralLookupLoadResult._(referral: referral);
  }

  factory PhysiotherapyReferralLookupLoadResult.notFound() {
    return const PhysiotherapyReferralLookupLoadResult._();
  }

  factory PhysiotherapyReferralLookupLoadResult.unavailable() {
    return const PhysiotherapyReferralLookupLoadResult._();
  }

  bool get isFound => referral != null;
}
