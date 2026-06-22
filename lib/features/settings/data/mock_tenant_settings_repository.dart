import '../../../core/auth/auth_session.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_refresher.dart';
import '../../../core/session/mock_tenant_context_bridge.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../lab_orders/models/lab_order_catalog_settings.dart';
import '../models/patient_registration_settings.dart';
import '../models/tenant_financial_feature_settings.dart';
import '../models/tenant_preferences.dart';
import '../models/tenant_role_access_settings.dart';
import '../models/tenant_security_settings.dart';
import 'tenant_settings_repository.dart';

class MockTenantSettingsRepository implements TenantSettingsRepository {
  const MockTenantSettingsRepository();

  static String logoStoragePath = '';
  static String bannerStoragePath = '';
  static PatientRegistrationSettings patientRegistrationSettings =
      const PatientRegistrationSettings();
  static TenantSecuritySettings securitySettings =
      TenantSecuritySettings.defaults;
  static TenantFinancialFeatureSettings financialFeatureSettings =
      TenantFinancialFeatureSettings.defaults;
  static LabOrderCatalogSettings labOrderCatalogSettings =
      LabOrderCatalogSettings.defaults;

  TenantBasicInfo _basicFromContextOrSettings() {
    final tenant = ActiveTenantContextStore.current?.tenant;
    final settings = appSettingsController.settings;
    if (tenant != null) {
      return TenantBasicInfo(
        name: tenant.name,
        specialty: tenant.specialty,
        contact: TenantContactInfo(
          phone: settings.phone,
          email: settings.email,
          address: settings.address,
          website: settings.website,
        ),
        branding: TenantBrandingInfo(
          logoStoragePath: logoStoragePath,
          bannerStoragePath: bannerStoragePath,
        ),
      );
    }
    return TenantBasicInfo(
      name: settings.clinicName,
      specialty: settings.specialty,
      contact: TenantContactInfo(
        phone: settings.phone,
        email: settings.email,
        address: settings.address,
        website: settings.website,
      ),
      branding: TenantBrandingInfo(
        logoStoragePath: logoStoragePath,
        bannerStoragePath: bannerStoragePath,
      ),
    );
  }

  @override
  Future<TenantBasicInfo> loadBasicInfo() async => _basicFromContextOrSettings();

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
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.validation,
        'Klinik adı boş olamaz.',
      );
    }

    await appSettingsController.saveClinicProfile(
      clinicName: trimmedName,
      specialty: specialty.trim(),
      address: contact.address,
      phone: contact.phone,
      email: contact.email,
      website: contact.website,
    );
    ActiveTenantContextRefresher.refreshTenantBasicInfo(
      name: trimmedName,
      specialty: specialty.trim(),
    );
    MockTenantContextBridge.refreshTenantFromSettings();
  }

  @override
  Future<TenantPreferences> loadPreferences() async {
    final settings = appSettingsController.settings;
    return TenantPreferences(
      dateTimeFormat: settings.dateTimeFormat,
      themeMode: settings.themeMode,
      languageCode: settings.languageCode,
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
        'Hasta kayıt ayarlarını yalnızca doktor hesabı güncelleyebilir.',
      );
    }
    final validation = settings.validate();
    if (validation != null) {
      throw TenantSettingsRepositoryException(
        TenantSettingsFailure.validation,
        validation,
      );
    }
    patientRegistrationSettings = settings;
  }

  @override
  Future<void> updateBrandingPaths({
    String? logoStoragePath,
    String? bannerStoragePath,
  }) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Klinik görsellerini yalnızca doktor hesabı güncelleyebilir.',
      );
    }
    if (logoStoragePath != null && logoStoragePath.trim().isNotEmpty) {
      MockTenantSettingsRepository.logoStoragePath = logoStoragePath.trim();
    }
    if (bannerStoragePath != null && bannerStoragePath.trim().isNotEmpty) {
      MockTenantSettingsRepository.bannerStoragePath = bannerStoragePath.trim();
    }
  }

  @override
  Future<TenantSecuritySettings> loadSecuritySettings() async {
    return TenantSecuritySettings(
      autoLockDuration: appSettingsController.settings.autoLockDuration,
    );
  }

  @override
  Future<void> updateSecuritySettings(TenantSecuritySettings settings) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Güvenlik ayarlarını yalnızca doktor hesabı güncelleyebilir.',
      );
    }
    securitySettings = settings;
    await appSettingsController.applyTenantSecuritySettings(settings);
  }

  @override
  Future<TenantFinancialFeatureSettings> loadFinancialFeatureSettings() async {
    return financialFeatureSettings;
  }

  @override
  Future<TenantRoleAccessSettings> loadRoleAccessSettings() async {
    return TenantRoleAccessSettings.empty();
  }

  @override
  Future<LabOrderCatalogSettings> loadLabOrderCatalogSettings() async {
    return labOrderCatalogSettings;
  }

  @override
  Future<void> updateLabOrderCatalogSettings(
    LabOrderCatalogSettings settings,
  ) async {
    if (!AuthSession.canManageLabOrderTemplates) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Laboratuvar test listesini yalnızca yetkili kullanıcı düzenleyebilir.',
      );
    }
    labOrderCatalogSettings = settings;
  }

  @override
  Future<void> updatePreferences(TenantPreferences preferences) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    await appSettingsController.applyTenantPreferences(preferences);
  }
}
