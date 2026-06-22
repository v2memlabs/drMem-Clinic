import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import '../models/tenant_membership_user.dart';
import 'tenant_membership_error_mapper.dart';
import 'tenant_membership_failure.dart';
import 'tenant_membership_repository.dart';

class SupabaseTenantMembershipRepository implements TenantMembershipRepository {
  SupabaseTenantMembershipRepository(this._client);

  factory SupabaseTenantMembershipRepository.fromSupabase() {
    return SupabaseTenantMembershipRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.notConfigured,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.notConfigured),
      );
    }
  }

  void _ensureCanManage() {
    if (!AuthSession.canEditClinicProfile) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.forbidden,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.forbidden),
      );
    }
    if (ActiveTenantContextStore.current == null || !SessionReadiness.isReady) {
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.noActiveTenant,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.noActiveTenant),
      );
    }
  }

  @override
  Future<List<TenantMembershipUser>> listCurrentTenantMembers() async {
    _ensureConfigured();
    _ensureCanManage();
    try {
      final data = await _client.rpc('list_tenant_memberships_v1');
      return TenantMembershipUser.parseListResponse(data);
    } on PostgrestException catch (e) {
      final failure = TenantMembershipErrorMapper.mapPostgrest(e);
      throw TenantMembershipRepositoryException(
        failure,
        TenantMembershipErrorMapper.messageFor(failure),
      );
    } catch (e) {
      if (e is TenantMembershipRepositoryException) rethrow;
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.unknown,
        TenantMembershipErrorMapper.messageFor(TenantMembershipFailure.unknown),
      );
    }
  }

  @override
  Future<void> updateRole({
    required String membershipId,
    required String role,
  }) async {
    _ensureConfigured();
    _ensureCanManage();
    try {
      await _client.rpc(
        'update_tenant_membership_role_v1',
        params: {
          'p_membership_id': membershipId,
          'p_role': role,
        },
      );
    } on PostgrestException catch (e) {
      final failure = TenantMembershipErrorMapper.mapPostgrest(e);
      throw TenantMembershipRepositoryException(
        failure,
        TenantMembershipErrorMapper.messageFor(failure),
      );
    } catch (e) {
      if (e is TenantMembershipRepositoryException) rethrow;
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.unknown,
        'Rol güncellenemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  @override
  Future<void> updateStatus({
    required String membershipId,
    required String status,
  }) async {
    _ensureConfigured();
    _ensureCanManage();
    try {
      await _client.rpc(
        'update_tenant_membership_status_v1',
        params: {
          'p_membership_id': membershipId,
          'p_status': status,
        },
      );
    } on PostgrestException catch (e) {
      final failure = TenantMembershipErrorMapper.mapPostgrest(e);
      throw TenantMembershipRepositoryException(
        failure,
        TenantMembershipErrorMapper.messageFor(failure),
      );
    } catch (e) {
      if (e is TenantMembershipRepositoryException) rethrow;
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.unknown,
        'Durum güncellenemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  @override
  Future<void> updateLoginUsername({
    required String profileId,
    required String loginUsername,
  }) async {
    _ensureConfigured();
    _ensureCanManage();
    try {
      await _client.rpc(
        'set_profile_login_username_v1',
        params: {
          'p_profile_id': profileId,
          'p_login_username': loginUsername.trim(),
        },
      );
    } on PostgrestException catch (e) {
      final failure = TenantMembershipErrorMapper.mapPostgrest(e);
      throw TenantMembershipRepositoryException(
        failure,
        TenantMembershipErrorMapper.messageFor(failure),
      );
    } catch (e) {
      if (e is TenantMembershipRepositoryException) rethrow;
      throw TenantMembershipRepositoryException(
        TenantMembershipFailure.unknown,
        'Kullanıcı adı güncellenemedi. Lütfen tekrar deneyin.',
      );
    }
  }
}
