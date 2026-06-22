import '../models/physiotherapy_referral.dart';

/// Hasta detay rehab kartı — referral seçimi.
abstract final class PatientRehabReferralSummaryDisplay {
  static PhysiotherapyReferral? latest(List<PhysiotherapyReferral> referrals) {
    if (referrals.isEmpty) return null;
    final sorted = List<PhysiotherapyReferral>.from(referrals)
      ..sort((a, b) => b.referredAt.compareTo(a.referredAt));
    return sorted.first;
  }
}
