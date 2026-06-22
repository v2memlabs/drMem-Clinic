import '../models/physiotherapy_referral.dart';

class PhysiotherapyReferralDetailLoadResult {
  final PhysiotherapyReferral? referral;
  final String? errorMessage;

  const PhysiotherapyReferralDetailLoadResult._({
    this.referral,
    this.errorMessage,
  });

  factory PhysiotherapyReferralDetailLoadResult.success(
    PhysiotherapyReferral referral,
  ) {
    return PhysiotherapyReferralDetailLoadResult._(referral: referral);
  }

  factory PhysiotherapyReferralDetailLoadResult.failure(String message) {
    return PhysiotherapyReferralDetailLoadResult._(errorMessage: message);
  }

  factory PhysiotherapyReferralDetailLoadResult.notFound() {
    return const PhysiotherapyReferralDetailLoadResult._();
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
