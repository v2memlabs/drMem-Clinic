import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/exercises/data/exercise_plan_repository_failure.dart';
import 'package:v2mem_clinic/features/exercises/data/exercise_plan_repository_provider.dart';
import 'package:v2mem_clinic/features/exercises/data/mock_async_exercise_plan_repository_adapter.dart';
import 'package:v2mem_clinic/features/exercises/data/supabase_async_exercise_plan_repository_stub.dart';
import 'package:v2mem_clinic/features/exercises/data/supabase_exercise_plan_repository.dart';

void main() {
  tearDown(() {
    ExercisePlanRepositoryProvider.clearTestOverrides();
    ExercisePlanRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('exercise plans capability flag is true', () {
    expect(
        OperationalRecordsRemoteCapabilities.exercisePlansTableReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ExercisePlanRepositoryProvider.resetCache();

    expect(
      ExercisePlanRepositoryProvider.asyncRepository,
      isA<MockAsyncExercisePlanRepositoryAdapter>(),
    );
    expect(ExercisePlanRepositoryProvider.usesRemoteExercisePlans, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ExercisePlanRepositoryProvider.resetCache();

    expect(
      ExercisePlanRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncExercisePlanRepositoryStub>(),
    );
    expect(ExercisePlanRepositoryProvider.usesRemoteExercisePlans, isFalse);
  });

  test('supabase without session does not resolve Supabase repository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ExercisePlanRepositoryProvider.resetCache();

    expect(
      ExercisePlanRepositoryProvider.asyncRepository,
      isNot(isA<SupabaseExercisePlanRepository>()),
    );
  });

  test('unavailable stub throws notConfigured', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ExercisePlanRepositoryProvider.resetCache();

    await expectLater(
      ExercisePlanRepositoryProvider.asyncRepository.getAll(),
      throwsA(
        isA<ExercisePlanRepositoryException>().having(
          (e) => e.reason,
          'reason',
          ExercisePlanRepositoryFailure.notConfigured,
        ),
      ),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ExercisePlanRepositoryProvider.resetCache();

    const stub = SupabaseAsyncExercisePlanRepositoryStub();
    ExercisePlanRepositoryProvider.testOverride = stub;

    expect(ExercisePlanRepositoryProvider.asyncRepository, same(stub));
  });
}
