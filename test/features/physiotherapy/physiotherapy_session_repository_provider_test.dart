import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/ftr_remote_capabilities.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/mock_async_physiotherapy_session_repository_adapter.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/supabase_async_physiotherapy_session_repository_stub.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/supabase_physiotherapy_session_repository.dart';

void main() {
  tearDown(() {
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('sessions capability flag is true', () {
    expect(FtrRemoteCapabilities.sessionsTableReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PhysiotherapySessionRepositoryProvider.resetCache();

    expect(
      PhysiotherapySessionRepositoryProvider.asyncRepository,
      isA<MockAsyncPhysiotherapySessionRepositoryAdapter>(),
    );
    expect(PhysiotherapySessionRepositoryProvider.usesRemoteSessions, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PhysiotherapySessionRepositoryProvider.resetCache();

    expect(
      PhysiotherapySessionRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncPhysiotherapySessionRepositoryStub>(),
    );
    expect(PhysiotherapySessionRepositoryProvider.usesRemoteSessions, isFalse);
  });

  test('supabase without session does not resolve SupabasePhysiotherapySessionRepository',
      () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PhysiotherapySessionRepositoryProvider.resetCache();

    expect(
      PhysiotherapySessionRepositoryProvider.asyncRepository,
      isNot(isA<SupabasePhysiotherapySessionRepository>()),
    );
  });
}
