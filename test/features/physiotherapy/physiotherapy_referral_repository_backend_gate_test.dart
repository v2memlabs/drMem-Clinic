import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/ftr_remote_capabilities.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_backend_gate.dart';

void main() {
  test('gate requires referralsTableReady capability', () {
    expect(FtrRemoteCapabilities.referralsTableReady, isTrue);

    expect(
      PhysiotherapyReferralRepositoryBackendGate.shouldUseRemoteReferrals(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isReferralRoleEligible: true,
      ),
      isTrue,
    );
  });

  test('mock backend disables remote', () {
    expect(
      PhysiotherapyReferralRepositoryBackendGate.shouldUseRemoteReferrals(
        isMockBackend: true,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isReferralRoleEligible: true,
      ),
      isFalse,
    );
  });

  test('non-eligible role disables remote', () {
    expect(
      PhysiotherapyReferralRepositoryBackendGate.shouldUseRemoteReferrals(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isReferralRoleEligible: false,
      ),
      isFalse,
    );
  });
}
