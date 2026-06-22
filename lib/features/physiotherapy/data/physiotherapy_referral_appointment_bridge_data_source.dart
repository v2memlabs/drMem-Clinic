import '../../../core/data/repository_registry.dart';
import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_list_refresh.dart';
import 'physiotherapy_referral_repository_failure.dart';

/// Fizyoterapi randevusu oluşturulunca yönlendirme kaydını günceller.
abstract final class PhysiotherapyReferralAppointmentBridgeDataSource {
  static Future<void> syncAfterAppointmentCreate({
    required String referralId,
    required String appointmentId,
    DateTime? plannedStartDate,
  }) async {
    final id = referralId.trim();
    final apptId = appointmentId.trim();
    if (id.isEmpty || apptId.isEmpty) return;

    try {
      final referral =
          await RepositoryRegistry.physiotherapyReferralsAsync.getById(id);
      if (referral == null) return;

      final targetStatus = referral.status == ReferralStatus.yeni
          ? ReferralStatus.devam
          : referral.status;

      await RepositoryRegistry.physiotherapyReferralsAsync.updateSafeFields(
        id,
        PhysiotherapyReferralSafeUpdate(
          appointmentId: apptId,
          status: targetStatus,
          plannedStartDate: plannedStartDate ?? referral.plannedStartDate,
        ),
      );
      PhysiotherapyReferralListRefresh.markStale();
    } on PhysiotherapyReferralRepositoryException {
      // Randevu kaydı başarılı; yönlendirme köprüsü sessizce atlanır.
    } catch (_) {}
  }
}
