import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/imaging/data/imaging_repository_failure.dart';
import 'package:v2mem_clinic/features/imaging/data/imaging_repository_provider.dart';
import 'package:v2mem_clinic/features/imaging/data/mock_async_imaging_repository_adapter.dart';
import 'package:v2mem_clinic/features/imaging/data/supabase_async_imaging_repository_stub.dart';
import 'package:v2mem_clinic/features/imaging/data/supabase_imaging_repository.dart';

void main() {
  tearDown(() {
    ImagingRepositoryProvider.clearTestOverrides();
    ImagingRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('imaging capability flag is true', () {
    expect(OperationalRecordsRemoteCapabilities.imagingNotesTableReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ImagingRepositoryProvider.resetCache();

    expect(
      ImagingRepositoryProvider.asyncRepository,
      isA<MockAsyncImagingRepositoryAdapter>(),
    );
    expect(ImagingRepositoryProvider.usesRemoteImagingNotes, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ImagingRepositoryProvider.resetCache();

    expect(
      ImagingRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncImagingRepositoryStub>(),
    );
    expect(ImagingRepositoryProvider.usesRemoteImagingNotes, isFalse);
  });

  test('supabase without session does not resolve Supabase repository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ImagingRepositoryProvider.resetCache();

    expect(
      ImagingRepositoryProvider.asyncRepository,
      isNot(isA<SupabaseImagingRepository>()),
    );
  });

  test('unavailable stub throws notConfigured', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ImagingRepositoryProvider.resetCache();

    await expectLater(
      ImagingRepositoryProvider.asyncRepository.getAll(),
      throwsA(
        isA<ImagingRepositoryException>().having(
          (e) => e.reason,
          'reason',
          ImagingRepositoryFailure.notConfigured,
        ),
      ),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ImagingRepositoryProvider.resetCache();

    const stub = SupabaseAsyncImagingRepositoryStub();
    ImagingRepositoryProvider.testOverride = stub;

    expect(ImagingRepositoryProvider.asyncRepository, same(stub));
  });
}
