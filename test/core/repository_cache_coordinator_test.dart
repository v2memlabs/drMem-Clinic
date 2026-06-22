import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/repository_cache_coordinator.dart';
import 'package:v2mem_clinic/core/data/repository_registry.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/session/auth_session_bridge.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_refresh.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_list_refresh.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_refresh.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/supabase_clinical_encounter_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_provider.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_refresh.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_provider.dart';
import 'package:v2mem_clinic/features/patients/data/supabase_async_patient_repository_stub.dart';
import 'package:v2mem_clinic/features/patients/data/supabase_patient_repository.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_provider.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AuthSessionBridge.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
    PatientRepositoryProvider.resetCache();
    AppointmentRepositoryProvider.resetCache();
    ClinicalEncounterRepositoryProvider.resetCache();
    ClinicalRoleSummaryRepositoryProvider.resetCache();
    PatientFileMetadataRepositoryProvider.resetCache();
    TimelineRepositoryProvider.resetCache();
  });

  ActiveTenantContext _tenant(String tenantId, {String role = AppRoles.doctor}) {
    return ActiveTenantContext(
      tenant: Tenant(id: tenantId, name: 'Klinik $tenantId'),
      membership: Membership(
        id: 'm-$tenantId',
        tenantId: tenantId,
        userId: 'u-1',
        role: role,
      ),
      profile: const UserProfile(userId: 'u-1', displayName: 'Test'),
    );
  }

  group('RepositoryRegistry.resetAllCaches', () {
    test('delegates to coordinator and clears patient async cache', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientRepositoryProvider.resetCache();
      final before = PatientRepositoryProvider.asyncRepository;
      RepositoryRegistry.resetAllCaches();
      PatientRepositoryProvider.resetCache();
      final after = PatientRepositoryProvider.asyncRepository;
      expect(identical(before, after), isFalse);
    });
  });

  group('RepositoryCacheCoordinator', () {
    test('resetAllRemoteProviderCaches allows new gate resolution', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doktor',
          role: AppRoles.doctor,
        ),
      );
      PatientRepositoryProvider.resetCache();
      final first = PatientRepositoryProvider.asyncRepository;
      RepositoryCacheCoordinator.resetAllRemoteProviderCaches();
      final second = PatientRepositoryProvider.asyncRepository;
      expect(first, isA<SupabaseAsyncPatientRepositoryStub>());
      expect(second, isA<SupabaseAsyncPatientRepositoryStub>());
      expect(PatientRepositoryProvider.usesRemotePatients, isFalse);
      expect(second, isNot(isA<SupabasePatientRepository>()));
    });

    test('logout clears provider caches', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      AuthSessionBridge.setFromMockUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doktor',
          role: AppRoles.doctor,
        ),
      );
      final cached = PatientRepositoryProvider.asyncRepository;
      AuthSessionBridge.clear();
      PatientRepositoryProvider.resetCache();
      final after = PatientRepositoryProvider.asyncRepository;
      expect(identical(cached, after), isFalse);
    });

    test('active tenant change resets caches', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ActiveTenantContextStore.clearSilently();
      PatientRepositoryProvider.resetCache();
      final first = PatientRepositoryProvider.asyncRepository;

      ActiveTenantContextStore.set(_tenant('tenant-a'));
      final second = PatientRepositoryProvider.asyncRepository;
      expect(identical(first, second), isFalse);

      ActiveTenantContextStore.set(_tenant('tenant-b'));
      final third = PatientRepositoryProvider.asyncRepository;
      expect(identical(second, third), isFalse);
    });

    test('same tenant id set does not reset provider cache', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      ActiveTenantContextStore.set(_tenant('tenant-a'));
      PatientRepositoryProvider.resetCache();
      final first = PatientRepositoryProvider.asyncRepository;
      ActiveTenantContextStore.set(_tenant('tenant-a'));
      final second = PatientRepositoryProvider.asyncRepository;
      expect(identical(first, second), isTrue);
    });

    test('resetForSessionContextChange marks list screens stale', () {
      final patientVersion = PatientListRefresh.version;
      final appointmentVersion = AppointmentListRefresh.version;
      final clinicalVersion = ClinicalEncounterListRefresh.version;
      final assistantVersion = AssistantClinicalSummaryListRefresh.version;
      RepositoryCacheCoordinator.resetForSessionContextChange();
      expect(PatientListRefresh.version, greaterThan(patientVersion));
      expect(AppointmentListRefresh.version, greaterThan(appointmentVersion));
      expect(
        ClinicalEncounterListRefresh.version,
        greaterThan(clinicalVersion),
      );
      expect(
        AssistantClinicalSummaryListRefresh.version,
        greaterThan(assistantVersion),
      );
    });
  });

  group('Role gate after cache reset', () {
    test('assistant does not get Supabase full clinical after doctor cache', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSessionBridge.setFromMockUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doktor',
          role: AppRoles.doctor,
        ),
      );
      ClinicalEncounterRepositoryProvider.resetCache();
      expect(
        ClinicalEncounterRepositoryProvider.asyncRepository,
        isNot(isA<SupabaseClinicalEncounterRepository>()),
      );

      AuthSessionBridge.clear();
      AuthSessionBridge.setFromMockUser(
        AppUser(
          id: 'a1',
          username: 'asst',
          displayName: 'Asistan',
          role: AppRoles.assistant,
        ),
      );
      ClinicalEncounterRepositoryProvider.resetCache();
      expect(
        ClinicalEncounterRepositoryProvider.asyncRepository,
        isNot(isA<SupabaseClinicalEncounterRepository>()),
      );
      expect(
        ClinicalEncounterRepositoryProvider.usesRemoteClinicalEncounters,
        isFalse,
      );
    });

    test('nurse does not enable timeline remote', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSessionBridge.setFromMockUser(
        AppUser(
          id: 'n1',
          username: 'nurse',
          displayName: 'Hemşire',
          role: AppRoles.nurse,
        ),
      );
      TimelineRepositoryProvider.resetCache();
      expect(TimelineRepositoryProvider.usesRemotePatientTimeline, isFalse);
    });
  });
}
