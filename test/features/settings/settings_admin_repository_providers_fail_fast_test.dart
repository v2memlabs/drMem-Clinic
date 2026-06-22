import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_stub.dart';
import 'package:v2mem_clinic/features/patient_tags/data/mock_patient_tag_repository.dart';
import 'package:v2mem_clinic/features/patient_tags/data/patient_tag_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_tags/data/patient_tag_repository_stub.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_repository_stub.dart';
import 'package:v2mem_clinic/features/settings/data/mock_profile_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository_stub.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_repository_stub.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_repository_stub.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_subscription_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_subscription_repository_stub.dart';

void main() {
  tearDown(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ProfileSettingsRepositoryProvider.resetCache();
    ClinicWorkflowSettingsRepositoryProvider.resetCache();
    TenantMembershipRepositoryProvider.resetCache();
    TenantSubscriptionRepositoryProvider.resetCache();
    TenantInviteRepositoryProvider.resetCache();
    PatientTagRepositoryProvider.resetCache();
    PatientFileStorageRepositoryProvider.resetCache();
  });

  test('profile mock backend uses mock repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ProfileSettingsRepositoryProvider.resetCache();
    expect(
      ProfileSettingsRepositoryProvider.repository,
      isA<MockProfileSettingsRepository>(),
    );
  });

  test('profile supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ProfileSettingsRepositoryProvider.resetCache();
    expect(
      ProfileSettingsRepositoryProvider.repository,
      isA<ProfileSettingsRepositoryStub>(),
    );
  });

  test('profile unavailable read throws notConfigured', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ProfileSettingsRepositoryProvider.resetCache();

    await expectLater(
      ProfileSettingsRepositoryProvider.repository.loadMyProfile(),
      throwsA(
        isA<ProfileSettingsRepositoryException>().having(
          (e) => e.failure,
          'failure',
          ProfileSettingsFailure.notConfigured,
        ),
      ),
    );
  });

  test('clinic workflow supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ClinicWorkflowSettingsRepositoryProvider.resetCache();
    expect(
      ClinicWorkflowSettingsRepositoryProvider.repository,
      isA<ClinicWorkflowSettingsRepositoryStub>(),
    );
  });

  test('tenant membership supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    TenantMembershipRepositoryProvider.resetCache();
    expect(
      TenantMembershipRepositoryProvider.repository,
      isA<TenantMembershipRepositoryStub>(),
    );
  });

  test('tenant subscription supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    TenantSubscriptionRepositoryProvider.resetCache();
    expect(
      TenantSubscriptionRepositoryProvider.repository,
      isA<TenantSubscriptionRepositoryStub>(),
    );
  });

  test('tenant invite supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    TenantInviteRepositoryProvider.resetCache();
    expect(
      TenantInviteRepositoryProvider.repository,
      isA<TenantInviteRepositoryStub>(),
    );
  });

  test('patient tags mock backend uses mock repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PatientTagRepositoryProvider.resetCache();
    expect(
      PatientTagRepositoryProvider.repository,
      isA<MockPatientTagRepository>(),
    );
  });

  test('patient tags supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PatientTagRepositoryProvider.resetCache();
    expect(
      PatientTagRepositoryProvider.repository,
      isA<PatientTagRepositoryStub>(),
    );
  });

  test('patient file storage supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PatientFileStorageRepositoryProvider.resetCache();
    expect(
      PatientFileStorageRepositoryProvider.repository,
      isA<PatientFileStorageRepositoryStub>(),
    );
  });
}
