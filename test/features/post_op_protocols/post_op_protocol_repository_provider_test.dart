import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/mock_async_post_op_protocol_repository_adapter.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/post_op_protocol_repository_failure.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/post_op_protocol_repository_provider.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/supabase_async_post_op_protocol_repository_stub.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/supabase_post_op_protocol_repository.dart';

void main() {
  tearDown(() {
    PostOpProtocolRepositoryProvider.clearTestOverrides();
    PostOpProtocolRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('post-op protocols capability flag is true', () {
    expect(
      OperationalRecordsRemoteCapabilities.postOpProtocolsTableReady,
      isTrue,
    );
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PostOpProtocolRepositoryProvider.resetCache();

    expect(
      PostOpProtocolRepositoryProvider.asyncRepository,
      isA<MockAsyncPostOpProtocolRepositoryAdapter>(),
    );
    expect(PostOpProtocolRepositoryProvider.usesRemotePostOpProtocols, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PostOpProtocolRepositoryProvider.resetCache();

    expect(
      PostOpProtocolRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncPostOpProtocolRepositoryStub>(),
    );
    expect(PostOpProtocolRepositoryProvider.usesRemotePostOpProtocols, isFalse);
  });

  test('supabase without session does not resolve Supabase repository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PostOpProtocolRepositoryProvider.resetCache();

    expect(
      PostOpProtocolRepositoryProvider.asyncRepository,
      isNot(isA<SupabasePostOpProtocolRepository>()),
    );
  });

  test('unavailable stub throws notConfigured', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PostOpProtocolRepositoryProvider.resetCache();

    await expectLater(
      PostOpProtocolRepositoryProvider.asyncRepository.getAll(),
      throwsA(
        isA<PostOpProtocolRepositoryException>().having(
          (e) => e.reason,
          'reason',
          PostOpProtocolRepositoryFailure.notConfigured,
        ),
      ),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PostOpProtocolRepositoryProvider.resetCache();

    const stub = SupabaseAsyncPostOpProtocolRepositoryStub();
    PostOpProtocolRepositoryProvider.testOverride = stub;

    expect(PostOpProtocolRepositoryProvider.asyncRepository, same(stub));
  });
}
