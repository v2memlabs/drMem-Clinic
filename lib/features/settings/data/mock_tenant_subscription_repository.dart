import '../../../core/auth/auth_session.dart';
import '../../../core/product/demo_freemium_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../patients/data/patient_count_data_source.dart';
import '../models/tenant_subscription_summary.dart';
import 'tenant_membership_repository_provider.dart';
import 'tenant_subscription_mapper.dart';
import 'tenant_subscription_repository.dart';

class MockTenantSubscriptionRepository implements TenantSubscriptionRepository {
  const MockTenantSubscriptionRepository();

  @override
  Future<TenantSubscriptionSummary> loadSummary() async {
    if (ActiveTenantContextStore.current == null && !AuthSession.isLoggedIn) {
      throw const TenantSubscriptionRepositoryException(
        TenantSubscriptionFailure.noActiveTenant,
        'Aktif klinik bulunamadı.',
      );
    }

    final patientResult = await PatientCountDataSource.load();
    final patientCount = patientResult.count ?? 0;

    var seatUsed = 1;
    if (AuthSession.canEditClinicProfile) {
      try {
        final members =
            await TenantMembershipRepositoryProvider.repository
                .listCurrentTenantMembers();
        seatUsed = members
            .where((m) => m.status == 'active' || m.status == 'invited')
            .length;
      } catch (_) {
        seatUsed = 1;
      }
    }

    return TenantSubscriptionMapper.fromParts(
      subscriptionRow: const {
        'plan_key': 'demo',
        'status': 'active',
      },
      usageLimitRows: [
        {
          'metric_key': 'patient_records',
          'limit_value': DemoFreemiumConfig.demoPatientRecordLimit,
        },
      ],
      seatUsed: seatUsed,
      patientCount: patientCount,
      fromRemoteRecord: false,
    );
  }
}
