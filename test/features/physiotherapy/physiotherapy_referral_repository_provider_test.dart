import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/ftr_remote_capabilities.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/mock_async_physiotherapy_referral_repository_adapter.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/supabase_async_physiotherapy_referral_repository_stub.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/supabase_physiotherapy_referral_repository.dart';

void main() {
  tearDown(() {
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('referrals capability flag is true', () {
    expect(FtrRemoteCapabilities.referralsTableReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PhysiotherapyReferralRepositoryProvider.resetCache();

    expect(
      PhysiotherapyReferralRepositoryProvider.asyncRepository,
      isA<MockAsyncPhysiotherapyReferralRepositoryAdapter>(),
    );
    expect(PhysiotherapyReferralRepositoryProvider.usesRemoteReferrals, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PhysiotherapyReferralRepositoryProvider.resetCache();

    expect(
      PhysiotherapyReferralRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncPhysiotherapyReferralRepositoryStub>(),
    );
    expect(PhysiotherapyReferralRepositoryProvider.usesRemoteReferrals, isFalse);
  });

  test('supabase without session does not resolve SupabasePhysiotherapyReferralRepository',
      () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PhysiotherapyReferralRepositoryProvider.resetCache();

    expect(
      PhysiotherapyReferralRepositoryProvider.asyncRepository,
      isNot(isA<SupabasePhysiotherapyReferralRepository>()),
    );
  });
}
