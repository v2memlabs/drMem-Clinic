import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/repository_registry.dart';
import 'package:v2mem_clinic/features/timeline/data/mock_timeline_repository.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_provider.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_stub.dart';import 'package:v2mem_clinic/features/timeline/data/supabase_timeline_repository.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    TimelineRepositoryProvider.resetCache();
    AuthSession.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('TimelineRepositoryProvider', () {
    test('mock backend uses mock timeline repository', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      expect(
        TimelineRepositoryProvider.repository,
        isA<MockTimelineRepository>(),
      );      expect(
        TimelineRepositoryProvider.usesRemotePatientTimeline,
        isFalse,
      );
    });

    test('registry patientTimeline resolves mock repository on mock', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      expect(RepositoryRegistry.patientTimeline, isA<MockTimelineRepository>());      expect(RepositoryRegistry.usesRemotePatientTimeline, isFalse);
    });

    test('nurse does not enable remote flag', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'n1',
          username: 'nurse',
          displayName: 'Hemşire',
          role: AppRoles.nurse,
        ),
      );
      TimelineRepositoryProvider.resetCache();

      expect(
        TimelineRepositoryProvider.usesRemotePatientTimeline,
        isFalse,
      );
      expect(
        TimelineRepositoryProvider.repository,
        isA<TimelineRepositoryStub>(),
      );
    });

    test('doctor on supabase without init still uses stub', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doktor',
          role: AppRoles.doctor,
        ),
      );
      TimelineRepositoryProvider.resetCache();

      expect(
        TimelineRepositoryProvider.repository,
        isA<TimelineRepositoryStub>(),
      );
      expect(
        TimelineRepositoryProvider.repository,
        isNot(isA<SupabaseTimelineRepository>()),
      );
    });
  });
}
