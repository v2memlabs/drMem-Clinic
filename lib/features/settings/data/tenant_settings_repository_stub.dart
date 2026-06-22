import '../../lab_orders/models/lab_order_catalog_settings.dart';
import '../models/patient_registration_settings.dart';
import '../models/tenant_financial_feature_settings.dart';
import '../models/tenant_preferences.dart';
import '../models/tenant_role_access_settings.dart';
import '../models/tenant_security_settings.dart';
import 'tenant_settings_repository.dart';

class TenantSettingsRepositoryStub implements TenantSettingsRepository {
  const TenantSettingsRepositoryStub();

  Never _notConfigured() => throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.notConfigured,
        'Klinik ayarları şu anda kullanıma hazır değil.',
      );

  @override
  Future<TenantBasicInfo> loadBasicInfo() async => _notConfigured();

  @override
  Future<void> updateBasicInfo({
    required String name,
    required String specialty,
    required String timezone,
    required TenantContactInfo contact,
  }) async =>
      _notConfigured();

  @override
  Future<TenantPreferences> loadPreferences() async => _notConfigured();

  @override
  Future<void> updatePreferences(TenantPreferences preferences) async =>
      _notConfigured();

  @override
  Future<void> updateBrandingPaths({
    String? logoStoragePath,
    String? bannerStoragePath,
  }) async =>
      _notConfigured();

  @override
  Future<PatientRegistrationSettings> loadPatientRegistrationSettings() async =>
      _notConfigured();

  @override
  Future<void> updatePatientRegistrationSettings(
    PatientRegistrationSettings settings,
  ) async =>
      _notConfigured();

  @override
  Future<TenantSecuritySettings> loadSecuritySettings() async =>
      _notConfigured();

  @override
  Future<void> updateSecuritySettings(TenantSecuritySettings settings) async =>
      _notConfigured();

  @override
  Future<TenantFinancialFeatureSettings> loadFinancialFeatureSettings() async =>
      TenantFinancialFeatureSettings.defaults;

  @override
  Future<TenantRoleAccessSettings> loadRoleAccessSettings() async =>
      TenantRoleAccessSettings.empty();

  @override
  Future<LabOrderCatalogSettings> loadLabOrderCatalogSettings() async =>
      LabOrderCatalogSettings.defaults;

  @override
  Future<void> updateLabOrderCatalogSettings(
    LabOrderCatalogSettings settings,
  ) async =>
      _notConfigured();
}
