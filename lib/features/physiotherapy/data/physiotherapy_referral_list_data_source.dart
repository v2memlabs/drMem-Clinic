import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/physiotherapy_referral.dart';
import 'physiotherapy_referral_list_load_result.dart';
import 'physiotherapy_referral_repository_failure.dart';
import 'physiotherapy_referral_user_messages.dart';
import 'physiotherapy_referral_workflow.dart';

abstract final class PhysiotherapyReferralListDataSource {
  static Future<PhysiotherapyReferralListLoadResult> load({
    String? patientId,
    required String query,
    ReferralStatus? statusFilter,
    bool pendingOnly = false,
  }) async {
    try {
      final repo = RepositoryRegistry.physiotherapyReferralsAsync;
      final list = await repo.getFiltered(
        patientId: patientId,
        query: query,
        statusEnumFilter: pendingOnly ? ReferralStatus.yeni : statusFilter,
      );

      Iterable<PhysiotherapyReferral> filtered = list;
      if (pendingOnly) {
        filtered = filtered.where((r) => r.isPendingPhysioAction);
      }
      if (AuthSession.isPhysiotherapist) {
        filtered = filtered.where(PhysiotherapyReferralWorkflow.isAssignedToCurrentUser);
        if (pendingOnly) {
          final currentId = ActiveTenantContextStore.current?.userId?.trim() ??
              AuthSession.currentUser?.id.trim();
          if (currentId != null && currentId.isNotEmpty) {
            filtered = filtered.where(
              (r) =>
                  r.assignedPhysiotherapistProfileId == null ||
                  r.assignedPhysiotherapistProfileId!.trim().isEmpty ||
                  r.assignedPhysiotherapistProfileId == currentId,
            );
          }
        }
      }

      final result = List<PhysiotherapyReferral>.from(filtered)
        ..sort((a, b) => b.referredAt.compareTo(a.referredAt));
      return PhysiotherapyReferralListLoadResult.success(result);
    } on PhysiotherapyReferralRepositoryException catch (e) {
      return PhysiotherapyReferralListLoadResult.failure(
        PhysiotherapyReferralListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PhysiotherapyReferralListLoadResult.failure(
        PhysiotherapyReferralListUserMessages.genericLoadFailure,
      );
    }
  }
}
