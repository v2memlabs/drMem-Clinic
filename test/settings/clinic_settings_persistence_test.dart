import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_refresher.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_order_catalog_settings.dart';
import 'package:v2mem_clinic/features/settings/models/patient_registration_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_preferences.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_security_settings.dart';
import 'package:v2mem_clinic/features/settings/settings_backend_labels.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeTenantSettingsRepository implements TenantSettingsRepository {
  TenantBasicInfo info = const TenantBasicInfo(
    name: 'Eski Klinik',
    specialty: 'Eski Branş',
  );
  TenantPreferences preferences = TenantPreferences.defaults;
  PatientRegistrationSettings patientRegistrationSettings =
      const PatientRegistrationSettings();
  TenantSecuritySettings securitySettings = TenantSecuritySettings.defaults;

  @override
  Future<TenantBasicInfo> loadBasicInfo() async => info;

  @override
  Future<void> updateBasicInfo({
    required String name,
    required String specialty,
    required String timezone,
    required TenantContactInfo contact,
  }) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Klinik bilgilerini yalnızca doktor hesabı güncelleyebilir.',
      );
    }
    info = TenantBasicInfo(
      name: name,
      specialty: specialty,
      timezone: timezone,
      contact: contact,
    );
  }

  @override
  Future<TenantPreferences> loadPreferences() async => preferences;

  @override
  Future<void> updatePreferences(TenantPreferences preferences) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    this.preferences = preferences;
  }

  @override
  Future<void> updateBrandingPaths({
    String? logoStoragePath,
    String? bannerStoragePath,
  }) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    final branding = info.branding.copyWith(
      logoStoragePath: logoStoragePath,
      bannerStoragePath: bannerStoragePath,
    );
    info = TenantBasicInfo(
      name: info.name,
      specialty: info.specialty,
      timezone: info.timezone,
      contact: info.contact,
      branding: branding,
    );
  }

  @override
  Future<PatientRegistrationSettings> loadPatientRegistrationSettings() async {
    return patientRegistrationSettings;
  }

  @override
  Future<void> updatePatientRegistrationSettings(
    PatientRegistrationSettings settings,
  ) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    patientRegistrationSettings = settings;
  }

  @override
  Future<TenantSecuritySettings> loadSecuritySettings() async {
    return securitySettings;
  }

  @override
  Future<void> updateSecuritySettings(TenantSecuritySettings settings) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    securitySettings = settings;
  }

  @override
  Future<TenantFinancialFeatureSettings> loadFinancialFeatureSettings() async {
    return TenantFinancialFeatureSettings.defaults;
  }

  @override
  Future<TenantRoleAccessSettings> loadRoleAccessSettings() async {
    return TenantRoleAccessSettings.empty();
  }

  @override
  Future<LabOrderCatalogSettings> loadLabOrderCatalogSettings() async {
    return LabOrderCatalogSettings.defaults;
  }

  @override
  Future<void> updateLabOrderCatalogSettings(
    LabOrderCatalogSettings settings,
  ) async {}
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
  });

  ActiveTenantContext contextForRole(String role) {
    return ActiveTenantContext(
      tenant: const Tenant(id: 'tenant-1', name: 'Eski Klinik', specialty: 'Eski Branş'),
      membership: Membership(
        id: 'm-1',
        tenantId: 'tenant-1',
        userId: 'profile-1',
        role: role,
      ),
      profile: const UserProfile(userId: 'profile-1', displayName: 'Kullanıcı'),
    );
  }

  test('doctor can update tenant basic info and refresh context', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-1',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    // Mock giriş tenant'ı ayarlardan yeniden bağlar; test tenant'ını sonra yaz.
    ActiveTenantContextStore.set(contextForRole(AppRoles.doctor));
    final repo = _FakeTenantSettingsRepository();

    await repo.updateBasicInfo(
      name: 'Yeni Klinik',
      specialty: 'Ortopedi',
      timezone: 'Europe/Istanbul',
      contact: const TenantContactInfo(phone: '0212 000 00 00'),
    );
    ActiveTenantContextRefresher.refreshTenantBasicInfo(
      name: 'Yeni Klinik',
      specialty: 'Ortopedi',
    );

    expect(ActiveTenantContextStore.current?.tenant.name, 'Yeni Klinik');
    expect(SettingsBackendLabels.activeClinicDisplayName, 'Yeni Klinik');
  });

  test('assistant cannot update tenant basic info', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-2',
        username: 'a@test.local',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ActiveTenantContextStore.set(contextForRole(AppRoles.assistant));
    final repo = _FakeTenantSettingsRepository();

    expect(
      () => repo.updateBasicInfo(
        name: 'Hack',
        specialty: 'X',
        timezone: 'UTC',
        contact: const TenantContactInfo(),
      ),
      throwsA(
        isA<TenantSettingsRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantSettingsFailure.forbidden,
        ),
      ),
    );
  });
}
