import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_data_source.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_user_messages.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_provider.dart';

void main() {
  tearDown(() {
    TimelineRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('TimelineListDataSource', () {
    test('empty patientId requires patient context', () async {
      final result = await TimelineListDataSource.load(patientId: '');
      expect(result.requiresPatientContext, isTrue);
    });

    test('mock backend returns success via mock timeline repository', () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      final result = await TimelineListDataSource.load(patientId: 'p1');
      expect(result.isNotConfigured, isFalse);
      expect(result.hasError, isFalse);
    });  });

  group('TimelineListUserMessages', () {
    test('network message hides technical enum names', () {
      expect(
        TimelineListUserMessages.networkError,
        isNot(contains('TimelineRepositoryFailure')),
      );
      expect(
        TimelineListUserMessages.networkError,
        isNot(contains('Postgrest')),
      );
    });
  });
}
