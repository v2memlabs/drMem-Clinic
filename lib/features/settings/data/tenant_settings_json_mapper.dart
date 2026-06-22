import '../../../core/settings/app_settings.dart';
import '../../lab_orders/models/lab_order_catalog_settings.dart';
import '../models/patient_registration_settings.dart';
import '../models/patient_required_field.dart';
import '../models/tenant_financial_feature_settings.dart';
import '../models/tenant_preferences.dart';
import '../models/tenant_security_settings.dart';
import 'tenant_settings_repository.dart';

/// `tenants.settings_json` — tercihler + iletişim alanları birleşik okuma/yazma.
abstract final class TenantSettingsJsonMapper {
  static const _contactKey = 'contact';
  static const _brandingKey = 'branding';
  static const _patientKey = 'patient';
  static const _securityKey = 'security';
  static const _financialKey = 'financial';
  static const _labOrderKey = 'lab_order';

  static TenantPreferences preferencesFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return TenantPreferences.defaults;
    }
    final formatRaw = json['date_time_format'];
    final format = formatRaw is String
        ? DateTimeFormatKind.fromStorage(formatRaw)
        : TenantPreferences.defaults.dateTimeFormat;
    final weekStart = json['week_start'] is String
        ? json['week_start'] as String
        : TenantPreferences.defaults.weekStart;
    final languageCode = json['language_code'] is String
        ? json['language_code'] as String
        : TenantPreferences.defaults.languageCode;
    final themeRaw = json['theme_mode'];
    final themeMode = themeRaw is String
        ? AppThemeModeKind.fromStorage(themeRaw)
        : TenantPreferences.defaults.themeMode;
    final currencyCode = json['currency_code'] is String
        ? json['currency_code'] as String
        : TenantPreferences.defaults.currencyCode;
    return TenantPreferences(
      dateTimeFormat: format,
      weekStart: weekStart,
      languageCode: languageCode,
      themeMode: themeMode,
      currencyCode: currencyCode,
    );
  }

  static Map<String, dynamic> preferencesToJson(TenantPreferences preferences) {
    return {
      'date_time_format': preferences.dateTimeFormat.name,
      'week_start': preferences.weekStart,
      'language_code': preferences.languageCode,
      'theme_mode': preferences.themeMode.name,
      'currency_code': preferences.currencyCode,
    };
  }

  static TenantContactInfo contactFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const TenantContactInfo();
    }
    final nested = json[_contactKey];
    final source = nested is Map<String, dynamic> ? nested : json;
    return TenantContactInfo(
      phone: _stringField(source['phone']),
      email: _stringField(source['email']),
      address: _stringField(source['address']),
      website: _stringField(source['website']),
    );
  }

  static Map<String, dynamic> contactToJson(TenantContactInfo contact) {
    return {
      _contactKey: {
        'phone': contact.phone,
        'email': contact.email,
        'address': contact.address,
        'website': contact.website,
      },
    };
  }

  static Map<String, dynamic> mergePreferences(
    Map<String, dynamic>? existing,
    TenantPreferences preferences,
  ) {
    final next = contactToJson(contactFromJson(existing));
    next.addAll(preferencesToJson(preferences));
    return next;
  }

  static Map<String, dynamic> mergeContact(
    Map<String, dynamic>? existing,
    TenantContactInfo contact,
  ) {
    final next = preferencesToJson(preferencesFromJson(existing));
    next.addAll(contactToJson(contact));
    return next;
  }

  static TenantBrandingInfo brandingFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const TenantBrandingInfo();
    }
    final nested = json[_brandingKey];
    final source = nested is Map<String, dynamic> ? nested : json;
    return TenantBrandingInfo(
      logoStoragePath: _stringField(source['logo_path']),
      bannerStoragePath: _stringField(source['banner_path']),
    );
  }

  static Map<String, dynamic> brandingToJson(TenantBrandingInfo branding) {
    return {
      _brandingKey: {
        'logo_path': branding.logoStoragePath,
        'banner_path': branding.bannerStoragePath,
      },
    };
  }

  static PatientRegistrationSettings patientFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const PatientRegistrationSettings();
    }
    final nested = json[_patientKey];
    final source = nested is Map<String, dynamic> ? nested : json;
    final format = _stringField(source['file_number_format']);
    final paddingRaw = source['file_number_seq_padding'];
    final padding = paddingRaw is int
        ? paddingRaw
        : paddingRaw is num
            ? paddingRaw.toInt()
            : int.tryParse('$paddingRaw') ??
                PatientRegistrationSettings.defaultSeqPadding;
    final requiredRaw = source['required_fields'];
    final requiredFields = requiredRaw is List
        ? PatientRequiredField.fromStorageList(requiredRaw)
        : const <PatientRequiredField>{};

    return PatientRegistrationSettings(
      fileNumberFormat: format.isNotEmpty
          ? format
          : PatientRegistrationSettings.defaultFileNumberFormat,
      seqPadding: padding,
      requiredFields: requiredFields,
    );
  }

  static Map<String, dynamic> patientToJson(PatientRegistrationSettings patient) {
    return {
      _patientKey: {
        'file_number_format': patient.fileNumberFormat,
        'file_number_seq_padding': patient.seqPadding,
        'required_fields': PatientRequiredField.toStorageList(
          patient.requiredFields,
        ),
      },
    };
  }

  static Map<String, dynamic> mergePatient(
    Map<String, dynamic>? existing,
    PatientRegistrationSettings patient,
  ) {
    final next = <String, dynamic>{};
    if (existing != null) {
      next.addAll(Map<String, dynamic>.from(existing));
    }
    final patientJson = patientToJson(patient)[_patientKey];
    if (patientJson is Map<String, dynamic>) {
      next[_patientKey] = patientJson;
    }
    return next;
  }

  static TenantSecuritySettings securityFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return TenantSecuritySettings.defaults;
    }
    final nested = json[_securityKey];
    final source = nested is Map<String, dynamic> ? nested : json;
    final raw = source['auto_lock_duration'];
    final duration = raw is String
        ? AutoLockDurationKind.fromStorage(raw)
        : TenantSecuritySettings.defaults.autoLockDuration;
    return TenantSecuritySettings(autoLockDuration: duration);
  }

  static Map<String, dynamic> securityToJson(TenantSecuritySettings security) {
    return {
      _securityKey: {
        'auto_lock_duration': security.autoLockDuration.name,
      },
    };
  }

  static Map<String, dynamic> mergeSecurity(
    Map<String, dynamic>? existing,
    TenantSecuritySettings security,
  ) {
    final next = <String, dynamic>{};
    if (existing != null) {
      next.addAll(Map<String, dynamic>.from(existing));
    }
    final securityJson = securityToJson(security)[_securityKey];
    if (securityJson is Map<String, dynamic>) {
      next[_securityKey] = securityJson;
    }
    return next;
  }

  static TenantFinancialFeatureSettings financialFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null || json.isEmpty) {
      return TenantFinancialFeatureSettings.defaults;
    }
    return TenantFinancialFeatureSettings.fromJson(json);
  }

  static Map<String, dynamic> financialToJson(
    TenantFinancialFeatureSettings financial,
  ) {
    return {
      _financialKey: financial.toJson(),
    };
  }

  static Map<String, dynamic> mergeFinancial(
    Map<String, dynamic>? existing,
    TenantFinancialFeatureSettings financial,
  ) {
    final next = <String, dynamic>{};
    if (existing != null) {
      next.addAll(Map<String, dynamic>.from(existing));
    }
    final financialJson = financialToJson(financial)[_financialKey];
    if (financialJson is Map<String, dynamic>) {
      next[_financialKey] = financialJson;
    }
    return next;
  }

  static LabOrderCatalogSettings labOrderFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return LabOrderCatalogSettings.defaults;
    }
    final nested = json[_labOrderKey];
    final source = nested is Map<String, dynamic> ? nested : json;
    return LabOrderCatalogSettings.fromJson(source);
  }

  static Map<String, dynamic> labOrderToJson(LabOrderCatalogSettings settings) {
    return {
      _labOrderKey: settings.toJson(),
    };
  }

  static Map<String, dynamic> mergeLabOrder(
    Map<String, dynamic>? existing,
    LabOrderCatalogSettings settings,
  ) {
    final next = <String, dynamic>{};
    if (existing != null) {
      next.addAll(Map<String, dynamic>.from(existing));
    }
    final labJson = labOrderToJson(settings)[_labOrderKey];
    if (labJson is Map<String, dynamic>) {
      next[_labOrderKey] = labJson;
    }
    return next;
  }

  static Map<String, dynamic> mergeBranding(
    Map<String, dynamic>? existing,
    TenantBrandingInfo branding,
  ) {
    final next = <String, dynamic>{};
    if (existing != null) {
      next.addAll(Map<String, dynamic>.from(existing));
    }
    final brandingJson = brandingToJson(branding)[_brandingKey];
    if (brandingJson is Map<String, dynamic>) {
      next[_brandingKey] = brandingJson;
    }
    return next;
  }

  static String _stringField(Object? value) {
    return value is String ? value.trim() : '';
  }
}
