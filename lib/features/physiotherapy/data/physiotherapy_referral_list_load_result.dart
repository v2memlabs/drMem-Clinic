import '../models/physiotherapy_referral.dart';

class PhysiotherapyReferralListLoadResult {
  final List<PhysiotherapyReferral>? items;
  final String? errorMessage;

  const PhysiotherapyReferralListLoadResult._({this.items, this.errorMessage});

  factory PhysiotherapyReferralListLoadResult.success(
    List<PhysiotherapyReferral> items,
  ) {
    return PhysiotherapyReferralListLoadResult._(items: items);
  }

  factory PhysiotherapyReferralListLoadResult.failure(String message) {
    return PhysiotherapyReferralListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
