import 'package:flutter/foundation.dart';

import '../../../core/data/repository_registry.dart';
import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_list_refresh.dart';

/// FTR session create sonrası yönlendirme status senkronu.
///
/// Yalnız [PhysiotherapyReferralSafeUpdate.status] güncellenir.
/// Hatalar swallow edilir — session create başarısız olmaz.
abstract final class PhysiotherapyReferralStatusBridgeDataSource {
  /// v2.1 status geçiş kuralları — test edilebilir saf fonksiyon.
  @visibleForTesting
  static ReferralStatus? computeTargetStatus({
    required ReferralStatus current,
    required bool doctorNotificationNeeded,
  }) {
    if (current == ReferralStatus.tamamlandi ||
        current == ReferralStatus.iptal) {
      return null;
    }

    if (doctorNotificationNeeded) {
      if (current == ReferralStatus.doktor_degerlendirmesi_bekliyor) {
        return null;
      }
      return ReferralStatus.doktor_degerlendirmesi_bekliyor;
    }

    if (current == ReferralStatus.yeni) {
      return ReferralStatus.devam;
    }

    return null;
  }

  static Future<void> syncAfterSessionCreate({
    required String referralId,
    required bool doctorNotificationNeeded,
  }) async {
    final id = referralId.trim();
    if (id.isEmpty) return;

    try {
      final referral =
          await RepositoryRegistry.physiotherapyReferralsAsync.getById(id);
      if (referral == null) {
        if (kDebugMode) {
          debugPrint(
            'PhysiotherapyReferralStatusBridge: referral not found for id=$id',
          );
        }
        return;
      }

      final target = computeTargetStatus(
        current: referral.status,
        doctorNotificationNeeded: doctorNotificationNeeded,
      );
      if (target == null || target == referral.status) return;

      await RepositoryRegistry.physiotherapyReferralsAsync.updateSafeFields(
        id,
        PhysiotherapyReferralSafeUpdate(status: target),
      );
      PhysiotherapyReferralListRefresh.markStale();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'PhysiotherapyReferralStatusBridge: sync failed for referral id=$id',
        );
        debugPrint('$e');
        debugPrint('$stackTrace');
      }
    }
  }
}
