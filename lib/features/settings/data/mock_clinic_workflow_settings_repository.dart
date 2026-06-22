import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/clinic_workflow_settings.dart';
import 'clinic_workflow_settings_mapper.dart';
import 'clinic_workflow_settings_repository.dart';

/// Mock persistence — SharedPreferences `clinic_workflow_{tenantId}`.
///
/// Widget test ortamında platform kanalı takılabildiği için bellek önbelleği de kullanılır.
class MockClinicWorkflowSettingsRepository
    implements ClinicWorkflowSettingsRepository {
  static final Map<String, String> _memoryByTenant = {};

  static String storageKeyForTenant(String tenantId) =>
      'clinic_workflow_$tenantId';

  static ClinicWorkflowSettings? _parseRaw(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ClinicWorkflowSettingsMapper.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static bool _prefsPrimed = false;

  static void _primePrefsForMockBackend() {
    if (!AppBackendConfig.isMock || _prefsPrimed) return;
    _prefsPrimed = true;
    try {
      SharedPreferences.setMockInitialValues({});
    } catch (_) {}
  }

  static Future<String?> _readRaw(String tenantId) async {
    final key = storageKeyForTenant(tenantId);
    final cached = _memoryByTenant[key];
    if (cached != null) return cached;

    _primePrefsForMockBackend();
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClinicWorkflowSettings?> load() async {
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      return null;
    }

    return _parseRaw(await _readRaw(tenantId));
  }

  @override
  Future<void> save(ClinicWorkflowSettings settings) async {
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ClinicWorkflowSettingsRepositoryException(
        'Aktif klinik bulunamadı.',
      );
    }

    final key = storageKeyForTenant(tenantId);
    final json = jsonEncode(ClinicWorkflowSettingsMapper.toJson(settings));
    _memoryByTenant[key] = json;

    _primePrefsForMockBackend();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json);
    } catch (_) {
      // Test / kanal yok — bellek önbelleği yeterli.
    }
  }
}
