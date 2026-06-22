import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_provider.dart';
import 'package:v2mem_clinic/features/consents/data/mock_async_consent_repository_adapter.dart';
import 'package:v2mem_clinic/features/consents/data/supabase_consent_repository.dart';
import 'package:v2mem_clinic/features/consents/data/supabase_consent_repository_stub.dart';

void main() {
  tearDown(() {
    ConsentRepositoryProvider.clearTestOverrides();
    ConsentRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('consents capability flag is true', () {
    expect(OperationalRecordsRemoteCapabilities.consentsTableReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ConsentRepositoryProvider.resetCache();

    expect(
      ConsentRepositoryProvider.asyncRepository,
      isA<MockAsyncConsentRepositoryAdapter>(),
    );
    expect(ConsentRepositoryProvider.usesRemoteConsents, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ConsentRepositoryProvider.resetCache();

    expect(
      ConsentRepositoryProvider.asyncRepository,
      isA<SupabaseConsentRepositoryStub>(),
    );
    expect(ConsentRepositoryProvider.usesRemoteConsents, isFalse);
  });

  test('supabase without session does not resolve SupabaseConsentRepository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ConsentRepositoryProvider.resetCache();

    expect(
      ConsentRepositoryProvider.asyncRepository,
      isNot(isA<SupabaseConsentRepository>()),
    );
  });
}
