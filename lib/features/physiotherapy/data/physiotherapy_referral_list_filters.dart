import '../models/physiotherapy_referral.dart';

abstract final class PhysiotherapyReferralListFilters {
  static bool matchesQuery(PhysiotherapyReferral r, String lowerQuery) {
    if (r.patientName.toLowerCase().contains(lowerQuery)) return true;
    if (r.physiotherapistName.toLowerCase().contains(lowerQuery)) return true;
    if (r.diagnosisSummary.toLowerCase().contains(lowerQuery)) return true;
    if (r.treatmentGoal.toLowerCase().contains(lowerQuery)) return true;
    if (r.statusLabel.toLowerCase().contains(lowerQuery)) return true;
    if (r.referredBy.toLowerCase().contains(lowerQuery)) return true;
    if (r.notes.toLowerCase().contains(lowerQuery)) return true;
    if (r.doctorSummary.toLowerCase().contains(lowerQuery)) return true;
    return false;
  }

  static List<PhysiotherapyReferral> matchesQueryList(
    List<PhysiotherapyReferral> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((r) => matchesQuery(r, q)).toList();
  }
}
