import 'package:flutter/foundation.dart';

import '../../../core/data/repository_registry.dart';
import '../models/physiotherapy_referral.dart';
import '../models/physiotherapy_session_note.dart';
import 'patient_rehab_last_session_display.dart';
import 'patient_rehab_referral_summary_display.dart';
import 'patient_rehab_summary_load_result.dart';
import 'physiotherapy_referral_list_load_result.dart';
import 'physiotherapy_referral_repository_failure.dart';
import 'physiotherapy_referral_user_messages.dart';
import 'physiotherapy_session_repository_failure.dart';

abstract final class PatientRehabReferralSummaryDataSource {
  /// Hasta detay rehabilitasyon kartı — latest referral + son seans özeti.
  static Future<PatientRehabSummaryLoadResult> loadSummary(
    String patientId,
  ) async {
    try {
      final list = await RepositoryRegistry.physiotherapyReferralsAsync
          .getByPatientId(patientId);
      if (list.isEmpty) {
        return PatientRehabSummaryLoadResult.success(referrals: const []);
      }
      list.sort((a, b) => b.referredAt.compareTo(a.referredAt));

      final latestReferral = PatientRehabReferralSummaryDisplay.latest(list);
      final latestSession = await _loadLatestSessionForReferral(latestReferral);

      return PatientRehabSummaryLoadResult.success(
        referrals: list,
        latestSession: latestSession,
      );
    } on PhysiotherapyReferralRepositoryException catch (e) {
      return PatientRehabSummaryLoadResult.failure(
        PhysiotherapyReferralListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PatientRehabSummaryLoadResult.failure(
        PhysiotherapyReferralListUserMessages.genericLoadFailure,
      );
    }
  }

  /// Geriye uyumluluk — yalnız referral listesi.
  static Future<PhysiotherapyReferralListLoadResult> loadLatest(
    String patientId,
  ) async {
    final summary = await loadSummary(patientId);
    if (summary.hasError) {
      return PhysiotherapyReferralListLoadResult.failure(summary.errorMessage!);
    }
    return PhysiotherapyReferralListLoadResult.success(
      summary.referrals ?? const [],
    );
  }

  static Future<PhysiotherapySessionNote?> _loadLatestSessionForReferral(
    PhysiotherapyReferral? referral,
  ) async {
    if (referral == null) return null;
    final referralId = referral.id.trim();
    if (referralId.isEmpty) return null;

    try {
      final sessions = await RepositoryRegistry.physiotherapySessionsAsync
          .getByReferralId(referralId);
      return PatientRehabLastSessionDisplay.latestSessionFromSorted(sessions);
    } on PhysiotherapySessionRepositoryException catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'PatientRehabReferralSummaryDataSource: session load failed '
          'referralId=$referralId reason=$e',
        );
        debugPrint('$stackTrace');
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'PatientRehabReferralSummaryDataSource: session load failed '
          'referralId=$referralId',
        );
        debugPrint('$e');
        debugPrint('$stackTrace');
      }
      return null;
    }
  }
}
