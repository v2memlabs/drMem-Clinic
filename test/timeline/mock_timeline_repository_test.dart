import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/timeline/data/mock_timeline_repository.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_data_source.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_user_messages.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_provider.dart';

void main() {
  tearDown(() {
    TimelineRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('MockTimelineRepository', () {
    test('mock backend uses mock repository not throwing stub', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      expect(
        TimelineRepositoryProvider.repository,
        isA<MockTimelineRepository>(),
      );
    });

    test('list returns events for patient with mock data', () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      final result = await TimelineListDataSource.load(patientId: 'p1');

      expect(result.isNotConfigured, isFalse);
      expect(result.hasError, isFalse);
      expect(result.events, isNotEmpty);
      expect(
        result.events.any((e) => e.title.contains('Muayene')),
        isTrue,
      );
    });

    test('empty patient returns success empty not notConfigured', () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      final result = await TimelineListDataSource.load(
        patientId: 'p-empty-unknown',
      );

      expect(result.isNotConfigured, isFalse);
      expect(result.hasError, isFalse);
      expect(result.events, isEmpty);
    });

    test('events do not expose tenant or storage technical fields in title',
        () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      final result = await TimelineListDataSource.load(patientId: 'p1');
      for (final event in result.events) {
        expect(event.title.contains('tenant_id'), isFalse);
        expect(event.title.contains('storage_path'), isFalse);
        expect(event.subtitle?.contains('tenant_id') ?? false, isFalse);
      }
    });
  });

  group('TimelineListUserMessages mock empty', () {
    test('empty copy is non-technical', () {
      expect(
        TimelineListUserMessages.emptyForPatient,
        isNot(contains('notConfigured')),
      );
    });
  });
}
