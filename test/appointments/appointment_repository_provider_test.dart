import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_backend_gate.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_provider.dart';
import 'package:v2mem_clinic/features/appointments/data/mock_appointment_repository_adapter.dart';
import 'package:v2mem_clinic/features/appointments/data/mock_async_appointment_repository_adapter.dart';
import 'package:v2mem_clinic/features/appointments/data/supabase_async_appointment_repository_stub.dart';

void main() {
  tearDown(AppointmentRepositoryProvider.resetCache);

  group('AppointmentRepositoryBackendGate', () {
    test('remote when all gates pass', () {
      expect(
        AppointmentRepositoryBackendGate.shouldUseRemoteAppointments(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
        ),
        isTrue,
      );
    });

    test('mock when backend is mock', () {
      expect(
        AppointmentRepositoryBackendGate.shouldUseRemoteAppointments(
          isMockBackend: true,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
        ),
        isFalse,
      );
    });

    test('mock when no active tenant', () {
      expect(
        AppointmentRepositoryBackendGate.shouldUseRemoteAppointments(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: false,
        ),
        isFalse,
      );
    });

    test('mock when supabase not configured', () {
      expect(
        AppointmentRepositoryBackendGate.shouldUseRemoteAppointments(
          isMockBackend: false,
          isSupabaseConfigured: false,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
        ),
        isFalse,
      );
    });
  });

  group('AppointmentRepositoryProvider', () {
    test('sync current always mock adapter', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      expect(
        AppointmentRepositoryProvider.current,
        isA<MockAppointmentRepositoryAdapter>(),
      );
      expect(
        AppointmentRepositoryProvider.resolve(),
        isA<MockAppointmentRepositoryAdapter>(),
      );
    });

    test('async uses mock adapter when mock backend', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      AppointmentRepositoryProvider.resetCache();
      expect(
        AppointmentRepositoryProvider.asyncRepository,
        isA<MockAsyncAppointmentRepositoryAdapter>(),
      );
      expect(AppointmentRepositoryProvider.usesRemoteAppointments, isFalse);
    });

    test('async uses unavailable stub when supabase backend but gate fails', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AppointmentRepositoryProvider.resetCache();
      expect(
        AppointmentRepositoryProvider.asyncRepository,
        isA<SupabaseAsyncAppointmentRepositoryStub>(),
      );
      expect(AppointmentRepositoryProvider.usesRemoteAppointments, isFalse);
    });
  });
}
