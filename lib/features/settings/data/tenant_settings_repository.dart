import '../../lab_orders/models/lab_order_catalog_settings.dart';
import '../models/patient_registration_settings.dart';
import '../models/tenant_financial_feature_settings.dart';
import '../models/tenant_preferences.dart';
import '../models/tenant_role_access_settings.dart';
import '../models/tenant_security_settings.dart';

class TenantContactInfo {
  final String phone;
  final String email;
  final String address;
  final String website;

  const TenantContactInfo({
    this.phone = '',
    this.email = '',
    this.address = '',
    this.website = '',
  });
}

class TenantBrandingInfo {
  final String logoStoragePath;
  final String bannerStoragePath;

  const TenantBrandingInfo({
    this.logoStoragePath = '',
    this.bannerStoragePath = '',
  });

  TenantBrandingInfo copyWith({
    String? logoStoragePath,
    String? bannerStoragePath,
  }) {
    return TenantBrandingInfo(
      logoStoragePath: logoStoragePath ?? this.logoStoragePath,
      bannerStoragePath: bannerStoragePath ?? this.bannerStoragePath,
    );
  }
}

class TenantBasicInfo {
  final String name;
  final String specialty;
  final String timezone;
  final TenantContactInfo contact;
  final TenantBrandingInfo branding;

  const TenantBasicInfo({
    required this.name,
    this.specialty = '',
    this.timezone = 'Europe/Istanbul',
    this.contact = const TenantContactInfo(),
    this.branding = const TenantBrandingInfo(),
  });
}

/// Aktif tenant klinik bilgisi ve tercihleri.
abstract interface class TenantSettingsRepository {
  Future<TenantBasicInfo> loadBasicInfo();

  Future<void> updateBasicInfo({
    required String name,
    required String specialty,
    required String timezone,
    required TenantContactInfo contact,
  });

  Future<TenantPreferences> loadPreferences();

  Future<void> updatePreferences(TenantPreferences preferences);

  Future<void> updateBrandingPaths({
    String? logoStoragePath,
    String? bannerStoragePath,
  });

  Future<PatientRegistrationSettings> loadPatientRegistrationSettings();

  Future<void> updatePatientRegistrationSettings(
    PatientRegistrationSettings settings,
  );

  Future<TenantSecuritySettings> loadSecuritySettings();

  Future<void> updateSecuritySettings(TenantSecuritySettings settings);

  /// Salt okunur — yalnızca IT bakım konsolu yazar.
  Future<TenantFinancialFeatureSettings> loadFinancialFeatureSettings();

  /// Klinik rol erişim matrisi — salt okunur; IT bakım konsolu yazar.
  Future<TenantRoleAccessSettings> loadRoleAccessSettings();

  Future<LabOrderCatalogSettings> loadLabOrderCatalogSettings();

  Future<void> updateLabOrderCatalogSettings(LabOrderCatalogSettings settings);
}

enum TenantSettingsFailure {
  forbidden,
  noActiveTenant,
  validation,
  notConfigured,
  unknown,
}

class TenantSettingsRepositoryException implements Exception {
  const TenantSettingsRepositoryException(this.failure, this.message);

  final TenantSettingsFailure failure;
  final String message;

  @override
  String toString() => message;
}
