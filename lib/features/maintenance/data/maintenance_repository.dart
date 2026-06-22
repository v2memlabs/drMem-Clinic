import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/maintenance_config.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../settings/models/tenant_financial_feature_settings.dart';
import '../../settings/models/tenant_role_access_settings.dart';
import 'maintenance_models.dart';
import 'maintenance_provision_errors.dart';
import 'maintenance_provision_models.dart';

/// Maintenance RPC — anon + user JWT only.
class MaintenanceRepository {
  MaintenanceRepository(this._client);

  factory MaintenanceRepository.fromSupabase() {
    return MaintenanceRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureAvailable() {
    if (!AppMaintenanceConfig.isAvailable ||
        !AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const MaintenanceRepositoryException(
        MaintenanceFailure.notAvailable,
      );
    }
  }

  Future<MaintenancePingResult> ping() async {
    _ensureAvailable();
    try {
      final data = await _client.rpc('maintenance_ping');
      if (data is Map<String, dynamic>) {
        return MaintenancePingResult.fromJson(data);
      }
      return const MaintenancePingResult(ok: false, error: 'invalid_response');
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<MaintenanceBootstrapChain> getBootstrapChain({
    String? email,
    String? profileId,
    String? authUserId,
  }) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_get_bootstrap_chain',
        params: {
          'p_email': email?.trim().isEmpty == true ? null : email?.trim(),
          'p_profile_id': profileId,
          'p_auth_user_id': authUserId,
        },
      );
      if (data is Map<String, dynamic>) {
        return MaintenanceBootstrapChain.fromJson(data);
      }
      throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<List<MaintenanceTenantRow>> listTenants() async {
    _ensureAvailable();
    return _parseList(
      await _client.rpc('maintenance_list_tenants'),
      MaintenanceTenantRow.fromJson,
    );
  }

  Future<List<MaintenanceMembershipRow>> listMemberships({
    String? tenantId,
    String? profileId,
  }) async {
    _ensureAvailable();
    return _parseList(
      await _client.rpc(
        'maintenance_list_memberships',
        params: {
          'p_tenant_id': tenantId,
          'p_profile_id': profileId,
        },
      ),
      MaintenanceMembershipRow.fromJson,
    );
  }

  Future<List<MaintenanceProfileGapRow>> listProfileAuthGaps() async {
    _ensureAvailable();
    return _parseList(
      await _client.rpc('maintenance_list_profile_auth_gaps'),
      MaintenanceProfileGapRow.fromJson,
    );
  }

  Future<List<MaintenanceAuditEventRow>> listAuditEvents({int limit = 20}) async {
    _ensureAvailable();
    return _parseList(
      await _client.rpc('maintenance_list_audit_events', params: {'p_limit': limit}),
      MaintenanceAuditEventRow.fromJson,
    );
  }

  Future<void> linkProfileAuth({
    required String profileId,
    required String authUserId,
  }) async {
    _ensureAvailable();
    try {
      await _client.rpc(
        'maintenance_link_profile_auth',
        params: {
          'p_profile_id': profileId,
          'p_auth_user_id': authUserId,
        },
      );
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<String> createProfile({
    required String email,
    required String displayName,
  }) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_create_profile',
        params: {
          'p_email': email.trim(),
          'p_display_name': displayName.trim(),
        },
      );
      if (data is Map<String, dynamic>) {
        return data['profile_id'] as String;
      }
      throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<void> updateProfileDisplayName({
    required String profileId,
    required String displayName,
  }) async {
    _ensureAvailable();
    try {
      await _client.rpc(
        'maintenance_update_profile',
        params: {
          'p_profile_id': profileId,
          'p_display_name': displayName.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<TenantFinancialFeatureSettings> getTenantFinancialSettings(
    String tenantId,
  ) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_get_tenant_financial_settings',
        params: {'p_tenant_id': tenantId},
      );
      if (data is Map<String, dynamic> && data['ok'] == true) {
        final financial = data['financial'];
        if (financial is Map<String, dynamic>) {
          return TenantFinancialFeatureSettings.fromJson(financial);
        }
        return TenantFinancialFeatureSettings.defaults;
      }
      throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<void> updateTenantFinancialSettings({
    required String tenantId,
    required TenantFinancialFeatureSettings settings,
  }) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_update_tenant_financial_settings',
        params: {
          'p_tenant_id': tenantId,
          'p_financial': settings.toJson(),
        },
      );
      if (data is! Map<String, dynamic> || data['ok'] != true) {
        throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
      }
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<TenantRoleAccessSettings> getTenantRoleAccessSettings(
    String tenantId,
  ) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_get_tenant_role_access_settings',
        params: {'p_tenant_id': tenantId},
      );
      if (data is Map<String, dynamic> && data['ok'] == true) {
        final roleAccess = data['role_access'];
        if (roleAccess is Map<String, dynamic>) {
          return TenantRoleAccessSettings.fromJson({'role_access': roleAccess});
        }
        return TenantRoleAccessSettings.empty();
      }
      throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<void> updateTenantRoleAccessSettings({
    required String tenantId,
    required TenantRoleAccessSettings settings,
  }) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_update_tenant_role_access_settings',
        params: {
          'p_tenant_id': tenantId,
          'p_role_access': settings.toJson(),
        },
      );
      if (data is! Map<String, dynamic> || data['ok'] != true) {
        throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
      }
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<void> updateTenantStatus({
    required String tenantId,
    required String status,
  }) async {
    _ensureAvailable();
    try {
      await _client.rpc(
        'maintenance_update_tenant_status',
        params: {
          'p_tenant_id': tenantId,
          'p_status': status,
        },
      );
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<String> createMembership({
    required String tenantId,
    required String profileId,
    required String role,
    String status = 'active',
  }) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_create_membership',
        params: {
          'p_tenant_id': tenantId,
          'p_profile_id': profileId,
          'p_role': role,
          'p_status': status,
        },
      );
      if (data is Map<String, dynamic>) {
        return data['membership_id'] as String;
      }
      throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<void> updateMembershipRole({
    required String membershipId,
    required String role,
  }) async {
    _ensureAvailable();
    try {
      await _client.rpc(
        'maintenance_update_membership_role',
        params: {
          'p_membership_id': membershipId,
          'p_role': role,
        },
      );
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<void> updateMembershipStatus({
    required String membershipId,
    required String status,
  }) async {
    _ensureAvailable();
    try {
      await _client.rpc(
        'maintenance_update_membership_status',
        params: {
          'p_membership_id': membershipId,
          'p_status': status,
        },
      );
    } on PostgrestException catch (e) {
      throw MaintenanceRepositoryException(_mapPostgrest(e));
    }
  }

  Future<MaintenanceTenantCreateResult> createTenantV2(
    MaintenanceTenantCreateRequest request,
  ) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_create_tenant_v2',
        params: {
          'p_name': request.name.trim(),
          'p_specialty': request.specialty?.trim(),
          'p_timezone': request.timezone.trim(),
          'p_status': request.status,
          'p_settings_json': request.settingsJson,
        },
      );
      if (data is Map<String, dynamic> && data['ok'] == true) {
        return MaintenanceTenantCreateResult.fromJson(data);
      }
      throw const MaintenanceProvisionException(
        MaintenanceProvisionFailure.invalidResponse,
      );
    } on MaintenanceProvisionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw MaintenanceProvisionException(
        MaintenanceProvisionErrorMapper.fromPostgrestMessage(e.message),
      );
    }
  }

  Future<MaintenanceUserProvisionResult> provisionInitialAdminV2(
    MaintenanceInitialAdminRequest request,
  ) async {
    _ensureAvailable();
    try {
      final response = await _client.functions.invoke(
        'maintenance-provision-user-v2',
        body: {
          'email': request.email.trim(),
          'display_name': request.displayName.trim(),
          'login_username': request.loginUsername.trim(),
          'tenant_id': request.tenantId,
          'role': 'doctor_admin',
          'membership_status': 'active',
          'mode': 'create',
        },
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const MaintenanceProvisionException(
          MaintenanceProvisionFailure.invalidResponse,
        );
      }

      if (payload['ok'] != true) {
        throw MaintenanceProvisionException(
          MaintenanceProvisionErrorMapper.fromFunctionError(
            payload['error'] as String?,
          ),
        );
      }

      return MaintenanceUserProvisionResult.fromJson(payload);
    } on MaintenanceProvisionException {
      rethrow;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map<String, dynamic> && details['error'] != null) {
        throw MaintenanceProvisionException(
          MaintenanceProvisionErrorMapper.fromFunctionError(
            details['error'] as String?,
          ),
        );
      }
      throw MaintenanceProvisionException(
        MaintenanceProvisionErrorMapper.fromFunctionError(e.reasonPhrase),
      );
    } catch (_) {
      throw const MaintenanceProvisionException(
        MaintenanceProvisionFailure.unknown,
      );
    }
  }

  Future<MaintenanceBootstrapStatus> getBootstrapStatusV2({
    required String tenantId,
    String? profileId,
    String? authUserId,
  }) async {
    _ensureAvailable();
    try {
      final data = await _client.rpc(
        'maintenance_bootstrap_status_v2',
        params: {
          'p_tenant_id': tenantId,
          'p_profile_id': profileId,
          'p_auth_user_id': authUserId,
        },
      );
      if (data is Map<String, dynamic>) {
        return MaintenanceBootstrapStatus.fromJson(data);
      }
      throw const MaintenanceProvisionException(
        MaintenanceProvisionFailure.invalidResponse,
      );
    } on MaintenanceProvisionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw MaintenanceProvisionException(
        MaintenanceProvisionErrorMapper.fromPostgrestMessage(e.message),
      );
    }
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) {
      throw const MaintenanceRepositoryException(MaintenanceFailure.invalidResponse);
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  MaintenanceFailure _mapPostgrest(PostgrestException e) {
    final msg = (e.message).toLowerCase();
    if (msg.contains('maintenance_disabled')) {
      return MaintenanceFailure.disabled;
    }
    if (msg.contains('maintenance_forbidden')) {
      return MaintenanceFailure.forbidden;
    }
    return MaintenanceFailure.unknown;
  }
}

enum MaintenanceFailure {
  notAvailable,
  disabled,
  forbidden,
  invalidResponse,
  unknown,
}

class MaintenanceRepositoryException implements Exception {
  final MaintenanceFailure reason;
  const MaintenanceRepositoryException(this.reason);
}

abstract final class MaintenanceUserMessages {
  static String forFailure(MaintenanceFailure reason) {
    switch (reason) {
      case MaintenanceFailure.notAvailable:
        return 'Bakım konsolu bu ortamda kullanılamıyor.';
      case MaintenanceFailure.disabled:
        return 'Bakım konsolu sunucuda devre dışı.';
      case MaintenanceFailure.forbidden:
        return 'Bu bakım işlemi için yetkiniz yok.';
      case MaintenanceFailure.invalidResponse:
        return 'Sunucu yanıtı işlenemedi.';
      case MaintenanceFailure.unknown:
        return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
    }
  }
}
