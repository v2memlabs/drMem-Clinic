import '../../../core/data/repository_registry.dart';
import '../models/physiotherapy_session_note.dart';
import 'physiotherapy_referral_status_bridge_data_source.dart';
import 'physiotherapy_session_list_refresh.dart';
import 'physiotherapy_session_repository_failure.dart';
import 'physiotherapy_session_repository_provider.dart';
import 'physiotherapy_session_user_messages.dart';

class PhysiotherapySessionFormSaveResult {
  final PhysiotherapySessionNote? session;
  final String? errorMessage;

  const PhysiotherapySessionFormSaveResult._({this.session, this.errorMessage});

  factory PhysiotherapySessionFormSaveResult.success(
    PhysiotherapySessionNote session,
  ) {
    return PhysiotherapySessionFormSaveResult._(session: session);
  }

  factory PhysiotherapySessionFormSaveResult.failure(String message) {
    return PhysiotherapySessionFormSaveResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PhysiotherapySessionFormDataSource {
  static Future<PhysiotherapySessionFormSaveResult> add(
    PhysiotherapySessionNote session,
  ) async {
    final referralId = session.referralId?.trim() ?? '';
    if (PhysiotherapySessionRepositoryProvider.usesRemoteSessions &&
        referralId.isEmpty) {
      return PhysiotherapySessionFormSaveResult.failure(
        PhysiotherapySessionFormUserMessages.referralRequired,
      );
    }

    try {
      final saved =
          await RepositoryRegistry.physiotherapySessionsAsync.add(session);
      PhysiotherapySessionListRefresh.markStale();

      final savedReferralId = saved.referralId?.trim() ?? '';
      if (savedReferralId.isNotEmpty) {
        await PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
          referralId: savedReferralId,
          doctorNotificationNeeded: saved.doctorNotificationNeeded,
        );
      }

      return PhysiotherapySessionFormSaveResult.success(saved);
    } on PhysiotherapySessionRepositoryException catch (e) {
      return PhysiotherapySessionFormSaveResult.failure(
        PhysiotherapySessionFormUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PhysiotherapySessionFormSaveResult.failure(
        PhysiotherapySessionFormUserMessages.saveFailure,
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
