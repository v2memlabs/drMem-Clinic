import '../models/physiotherapy_referral.dart';
import '../models/physiotherapy_session_note.dart';

/// Hasta detay rehabilitasyon kartı — referral listesi + opsiyonel son seans.
class PatientRehabSummaryLoadResult {
  final List<PhysiotherapyReferral>? referrals;
  final PhysiotherapySessionNote? latestSession;
  final String? errorMessage;

  const PatientRehabSummaryLoadResult._({
    this.referrals,
    this.latestSession,
    this.errorMessage,
  });

  factory PatientRehabSummaryLoadResult.success({
    required List<PhysiotherapyReferral> referrals,
    PhysiotherapySessionNote? latestSession,
  }) {
    return PatientRehabSummaryLoadResult._(
      referrals: referrals,
      latestSession: latestSession,
    );
  }

  factory PatientRehabSummaryLoadResult.failure(String message) {
    return PatientRehabSummaryLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
