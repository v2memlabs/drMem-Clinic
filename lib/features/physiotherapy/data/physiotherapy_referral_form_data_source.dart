import '../../clinical_encounter/data/clinical_encounter_ftr_bridge_data_source.dart';
import '../../../core/data/repository_registry.dart';
import '../models/physiotherapy_referral.dart';
import 'physiotherapy_referral_list_refresh.dart';
import 'physiotherapy_referral_repository_failure.dart';
import 'physiotherapy_referral_user_messages.dart';

class PhysiotherapyReferralFormSaveResult {
  final PhysiotherapyReferral? referral;
  final String? errorMessage;

  const PhysiotherapyReferralFormSaveResult._({this.referral, this.errorMessage});

  factory PhysiotherapyReferralFormSaveResult.success(
    PhysiotherapyReferral referral,
  ) {
    return PhysiotherapyReferralFormSaveResult._(referral: referral);
  }

  factory PhysiotherapyReferralFormSaveResult.failure(String message) {
    return PhysiotherapyReferralFormSaveResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PhysiotherapyReferralFormDataSource {
  static Future<PhysiotherapyReferralFormSaveResult> add(
    PhysiotherapyReferral referral,
  ) async {
    try {
      final saved =
          await RepositoryRegistry.physiotherapyReferralsAsync.add(referral);
      PhysiotherapyReferralListRefresh.markStale();

      final encounterId = saved.clinicalEncounterId?.trim();
      if (encounterId != null && encounterId.isNotEmpty) {
        await ClinicalEncounterFtrBridgeDataSource
            .syncReferralFlagAfterReferralCreate(encounterId);
      }

      return PhysiotherapyReferralFormSaveResult.success(saved);
    } on PhysiotherapyReferralRepositoryException catch (e) {
      return PhysiotherapyReferralFormSaveResult.failure(
        PhysiotherapyReferralFormUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PhysiotherapyReferralFormSaveResult.failure(
        PhysiotherapyReferralFormUserMessages.saveFailure,
      );
    }
  }

  static Future<String?> resolvePatientName(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;
    try {
      final patient = await RepositoryRegistry.patientsAsync.getById(pid);
      return patient?.fullName;
    } catch (_) {
      return null;
    }
  }
}
