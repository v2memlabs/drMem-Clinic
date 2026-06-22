import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../lab_orders/models/lab_order_catalog_settings.dart';
import '../models/patient_registration_settings.dart';
import '../models/tenant_financial_feature_settings.dart';
import '../models/tenant_preferences.dart';
import '../models/tenant_role_access_settings.dart';
import '../models/tenant_security_settings.dart';
import 'tenant_preferences_mapper.dart';
import 'tenant_settings_json_mapper.dart';
import 'tenant_settings_repository.dart';

class SupabaseTenantSettingsRepository implements TenantSettingsRepository {
  SupabaseTenantSettingsRepository(this._client);

  factory SupabaseTenantSettingsRepository.fromSupabase() {
    return SupabaseTenantSettingsRepository(Supabase.instance.client);
  }

  static const String table = 'tenants';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.notConfigured,
        'Uzak veritabanı yapılandırılmadı.',
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.noActiveTenant,
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  void _ensureCanEditClinic() {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Klinik bilgilerini yalnızca doktor hesabı güncelleyebilir.',
      );
    }
  }

  Map<String, dynamic>? _settingsJsonFromRow(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  TenantBasicInfo _mapBasicInfo(Map<String, dynamic> row) {
    final name = row['name'];
    final specialty = row['specialty'];
    final timezone = row['timezone'];
    final settingsJson = _settingsJsonFromRow(row['settings_json']);
    return TenantBasicInfo(
      name: name is String ? name.trim() : '',
      specialty: specialty is String ? specialty.trim() : '',
      timezone: timezone is String && timezone.trim().isNotEmpty
          ? timezone.trim()
          : 'Europe/Istanbul',
      contact: TenantSettingsJsonMapper.contactFromJson(settingsJson),
      branding: TenantSettingsJsonMapper.brandingFromJson(settingsJson),
    );
  }

  Future<Map<String, dynamic>?> _loadSettingsJson(String tenantId) async {
    final row = await _client
        .from(table)
        .select('settings_json')
        .eq('id', tenantId)
        .maybeSingle();
    if (row == null) return null;
    return _settingsJsonFromRow(row['settings_json']);
  }

  @override
  Future<TenantBasicInfo> loadBasicInfo() async {
    final tenantId = _requireTenantId();
    try {
      final row = await _client
          .from(table)
          .select('name, specialty, timezone, settings_json')
          .eq('id', tenantId)
          .maybeSingle();
      if (row == null) {
        throw const TenantSettingsRepositoryException(
          TenantSettingsFailure.noActiveTenant,
          'Klinik bilgileri bulunamadı.',
        );
      }
      return _mapBasicInfo(row);
    } on TenantSettingsRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Klinik bilgileri yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Klinik bilgileri yüklenemedi.',
      );
    }
  }

  @override
  Future<void> updateBasicInfo({
    required String name,
    required String specialty,
    required String timezone,
    required TenantContactInfo contact,
  }) async {
    _ensureCanEditClinic();
    final tenantId = _requireTenantId();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.validation,
        'Klinik adı boş olamaz.',
      );
    }

    try {
      final existing = await _loadSettingsJson(tenantId);
      final settingsJson = TenantSettingsJsonMapper.mergeContact(existing, contact);
      await _client.from(table).update({
        'name': trimmedName,
        'specialty': specialty.trim(),
        'timezone': timezone.trim().isEmpty ? 'Europe/Istanbul' : timezone.trim(),
        'settings_json': settingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tenantId);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Klinik bilgileri kaydedilemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Klinik bilgileri kaydedilemedi.',
      );
    }
  }

  @override
  Future<TenantPreferences> loadPreferences() async {
    final tenantId = _requireTenantId();
    try {
      final row = await _client
          .from(table)
          .select('settings_json')
          .eq('id', tenantId)
          .maybeSingle();
      if (row == null) {
        return TenantPreferences.defaults;
      }
      final json = _settingsJsonFromRow(row['settings_json']);
      return TenantPreferencesMapper.fromJson(json);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Tercihler yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Tercihler yüklenemedi.',
      );
    }
  }

  @override
  Future<PatientRegistrationSettings> loadPatientRegistrationSettings() async {
    final tenantId = _requireTenantId();
    try {
      final json = await _loadSettingsJson(tenantId);
      return TenantSettingsJsonMapper.patientFromJson(json);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Hasta kayıt ayarları yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Hasta kayıt ayarları yüklenemedi.',
      );
    }
  }

  @override
  Future<void> updatePatientRegistrationSettings(
    PatientRegistrationSettings settings,
  ) async {
    _ensureCanEditClinic();
    final validation = settings.validate();
    if (validation != null) {
      throw TenantSettingsRepositoryException(
        TenantSettingsFailure.validation,
        validation,
      );
    }

    final tenantId = _requireTenantId();
    try {
      final existing = await _loadSettingsJson(tenantId);
      final settingsJson = TenantSettingsJsonMapper.mergePatient(existing, settings);
      await _client.from(table).update({
        'settings_json': settingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tenantId);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Hasta kayıt ayarları kaydedilemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Hasta kayıt ayarları kaydedilemedi.',
      );
    }
  }

  @override
  Future<void> updateBrandingPaths({
    String? logoStoragePath,
    String? bannerStoragePath,
  }) async {
    _ensureCanEditClinic();
    final tenantId = _requireTenantId();

    try {
      final existing = await _loadSettingsJson(tenantId);
      final current = TenantSettingsJsonMapper.brandingFromJson(existing);
      final next = current.copyWith(
        logoStoragePath: logoStoragePath?.trim().isNotEmpty == true
            ? logoStoragePath!.trim()
            : null,
        bannerStoragePath: bannerStoragePath?.trim().isNotEmpty == true
            ? bannerStoragePath!.trim()
            : null,
      );
      final settingsJson = TenantSettingsJsonMapper.mergeBranding(existing, next);
      await _client.from(table).update({
        'settings_json': settingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tenantId);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Klinik görselleri kaydedilemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Klinik görselleri kaydedilemedi.',
      );
    }
  }

  @override
  Future<TenantSecuritySettings> loadSecuritySettings() async {
    final tenantId = _requireTenantId();
    try {
      final json = await _loadSettingsJson(tenantId);
      return TenantSettingsJsonMapper.securityFromJson(json);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Güvenlik ayarları yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Güvenlik ayarları yüklenemedi.',
      );
    }
  }

  @override
  Future<void> updateSecuritySettings(TenantSecuritySettings settings) async {
    _ensureCanEditClinic();
    final tenantId = _requireTenantId();

    try {
      final existing = await _loadSettingsJson(tenantId);
      final settingsJson = TenantSettingsJsonMapper.mergeSecurity(existing, settings);
      await _client.from(table).update({
        'settings_json': settingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tenantId);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Güvenlik ayarları kaydedilemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Güvenlik ayarları kaydedilemedi.',
      );
    }
  }

  @override
  Future<TenantFinancialFeatureSettings> loadFinancialFeatureSettings() async {
    final tenantId = _requireTenantId();
    try {
      final json = await _loadSettingsJson(tenantId);
      return TenantSettingsJsonMapper.financialFromJson(json);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Finansal özellik ayarları yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Finansal özellik ayarları yüklenemedi.',
      );
    }
  }

  @override
  Future<TenantRoleAccessSettings> loadRoleAccessSettings() async {
    final tenantId = _requireTenantId();
    try {
      final json = await _loadSettingsJson(tenantId);
      return TenantRoleAccessSettings.fromJson(json);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Rol erişim ayarları yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Rol erişim ayarları yüklenemedi.',
      );
    }
  }

  @override
  Future<LabOrderCatalogSettings> loadLabOrderCatalogSettings() async {
    final tenantId = _requireTenantId();
    try {
      final json = await _loadSettingsJson(tenantId);
      return TenantSettingsJsonMapper.labOrderFromJson(json);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Laboratuvar test listesi yüklenemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Laboratuvar test listesi yüklenemedi.',
      );
    }
  }

  @override
  Future<void> updateLabOrderCatalogSettings(
    LabOrderCatalogSettings settings,
  ) async {
    if (!AuthSession.canManageLabOrderTemplates) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Laboratuvar test listesini düzenleme yetkiniz yok.',
      );
    }
    final tenantId = _requireTenantId();
    try {
      final existing = await _loadSettingsJson(tenantId);
      final settingsJson =
          TenantSettingsJsonMapper.mergeLabOrder(existing, settings);
      await _client.from(table).update({
        'settings_json': settingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tenantId);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Laboratuvar test listesi kaydedilemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Laboratuvar test listesi kaydedilemedi.',
      );
    }
  }

  @override
  Future<void> updatePreferences(TenantPreferences preferences) async {
    _ensureCanEditClinic();
    final tenantId = _requireTenantId();

    try {
      final existing = await _loadSettingsJson(tenantId);
      final settingsJson = TenantSettingsJsonMapper.mergePreferences(existing, preferences);
      await _client.from(table).update({
        'settings_json': settingsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tenantId);
    } on PostgrestException catch (e) {
      throw TenantSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e, 'Tercihler kaydedilemedi.'),
      );
    } catch (_) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.unknown,
        'Tercihler kaydedilemedi.',
      );
    }
  }

  TenantSettingsFailure _mapPostgrest(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501' || code == 'PGRST301') {
      return TenantSettingsFailure.forbidden;
    }
    return TenantSettingsFailure.unknown;
  }

  String _safeMessage(PostgrestException e, String fallback) {
    final failure = _mapPostgrest(e);
    if (failure == TenantSettingsFailure.forbidden) {
      return 'Bu işlem için yetkiniz yok.';
    }
    return fallback;
  }
}

