import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_backend_gate.dart';

void main() {
  group('TimelineRepositoryBackendGate', () {
    test('mock backend denies remote', () {
      expect(
        TimelineRepositoryBackendGate.canUsePatientTimelineRemote(
          isMockBackend: true,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isTimelineRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('supabase without session denies remote', () {
      expect(
        TimelineRepositoryBackendGate.canUsePatientTimelineRemote(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: false,
          isSessionReady: false,
          hasActiveTenant: false,
          isTimelineRoleEligible: true,
        ),
        isFalse,
      );
    });

    test('nurse role eligible flag false denies remote', () {
      expect(
        TimelineRepositoryBackendGate.canUsePatientTimelineRemote(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isTimelineRoleEligible: false,
        ),
        isFalse,
      );
    });

    test('all infra and doctor role allows remote', () {
      expect(
        TimelineRepositoryBackendGate.canUsePatientTimelineRemote(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isTimelineRoleEligible: true,
        ),
        isTrue,
      );
    });
  });
}
