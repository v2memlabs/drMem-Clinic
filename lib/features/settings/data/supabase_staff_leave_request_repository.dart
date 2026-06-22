import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../settings/settings_product_labels.dart';
import '../models/staff_leave_record.dart';
import '../models/staff_leave_request.dart';
import 'staff_leave_record_mapper.dart';
import 'staff_leave_request_mapper.dart';
import 'staff_leave_request_repository.dart';

class SupabaseStaffLeaveRequestRepository
    implements StaffLeaveRequestRepository {
  SupabaseStaffLeaveRequestRepository(this._client);

  factory SupabaseStaffLeaveRequestRepository.fromSupabase() {
    return SupabaseStaffLeaveRequestRepository(Supabase.instance.client);
  }

  static const String table = 'staff_leave_requests';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const StaffLeaveRequestRepositoryException(
        'Supabase yapılandırması hazır değil.',
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const StaffLeaveRequestRepositoryException(
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  String _requireProfileId() {
    final fromCtx = ActiveTenantContextStore.current?.profile.userId;
    if (fromCtx != null && fromCtx.isNotEmpty) return fromCtx;
    final user = AuthSession.currentUser;
    if (user != null && user.id.isNotEmpty) return user.id;
    throw const StaffLeaveRequestRepositoryException(
      'Kullanıcı profili bulunamadı.',
    );
  }

  String _staffDisplayName() {
    final ctx = ActiveTenantContextStore.current;
    if (ctx != null && ctx.profile.displayName.trim().isNotEmpty) {
      return ctx.profile.displayName.trim();
    }
    return AuthSession.currentUser?.displayName ?? 'Personel';
  }

  String? _roleLabel() {
    final ctx = ActiveTenantContextStore.current;
    if (ctx != null) {
      return SettingsProductLabels.roleLabel(ctx.role);
    }
    final role = AuthSession.currentUser?.role;
    if (role == null) return null;
    return AppRoles.roleLabel(role);
  }

  List<StaffLeaveRequest> _mapRows(dynamic rows) {
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(StaffLeaveRequestMapper.fromRow)
        .toList();
  }

  @override
  Future<List<StaffLeaveRequest>> listMine() async {
    _requireTenantId();
    final profileId = _requireProfileId();
    try {
      final rows = await _client
          .from(table)
          .select()
          .eq('requester_profile_id', profileId)
          .order('created_at', ascending: false);
      return _mapRows(rows);
    } catch (_) {
      throw const StaffLeaveRequestRepositoryException(
        'İzin talepleri yüklenemedi.',
      );
    }
  }

  @override
  Future<List<StaffLeaveRequest>> listPending() async {
    _requireTenantId();
    try {
      final rows = await _client
          .from(table)
          .select()
          .eq('status', StaffLeaveRequestStatus.pending.dbValue)
          .order('starts_at', ascending: true);
      return _mapRows(rows);
    } catch (_) {
      throw const StaffLeaveRequestRepositoryException(
        'Bekleyen izin talepleri yüklenemedi.',
      );
    }
  }

  @override
  Future<int> countPending() async {
    final pending = await listPending();
    return pending.length;
  }

  @override
  Future<StaffLeaveRequest> create(StaffLeaveRequestDraft draft) async {
    _requireTenantId();
    StaffLeaveRequestMapper.validateDraft(
      draft,
      staffDisplayName: _staffDisplayName(),
      roleLabel: _roleLabel(),
    );

    try {
      final row = await _client.rpc(
        'create_staff_leave_request_v1',
        params: {
          'p_leave_type': draft.leaveType.dbValue,
          'p_starts_at': draft.startsAt.toUtc().toIso8601String(),
          'p_ends_at': draft.endsAt.toUtc().toIso8601String(),
          'p_note': draft.note,
          'p_staff_display_name': _staffDisplayName(),
          'p_role_label': _roleLabel(),
        },
      );
      if (row is! Map) {
        throw const StaffLeaveRequestRepositoryException(
          'İzin talebi gönderilemedi.',
        );
      }
      return StaffLeaveRequestMapper.fromRow(Map<String, dynamic>.from(row));
    } on StaffLeaveRecordValidationException catch (e) {
      throw StaffLeaveRequestRepositoryException(e.message);
    } on StaffLeaveRequestRepositoryException {
      rethrow;
    } catch (e) {
      throw StaffLeaveRequestRepositoryException(
        _mapCreateError(e),
      );
    }
  }

  String _mapCreateError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('auth_context_required') ||
        message.contains('profile_required')) {
      return 'Oturum bağlamı eksik. Çıkış yapıp tekrar giriş yapın.';
    }
    if (message.contains('invalid_range')) {
      return 'Bitiş zamanı başlangıçtan sonra olmalıdır.';
    }
    if (message.contains('does not exist') ||
        message.contains('create_staff_leave_request_v1')) {
      return 'İzin talebi servisi henüz güncellenmedi. Yöneticinize bildirin.';
    }
    return 'İzin talebi gönderilemedi.';
  }

  @override
  Future<void> approve(String requestId) async {
    _requireTenantId();
    try {
      await _client.rpc('approve_staff_leave_request_v1', params: {
        'p_request_id': requestId,
      });
    } catch (_) {
      throw const StaffLeaveRequestRepositoryException(
        'İzin talebi onaylanamadı.',
      );
    }
  }

  @override
  Future<void> reject(String requestId, {String? reason}) async {
    _requireTenantId();
    try {
      await _client.rpc('reject_staff_leave_request_v1', params: {
        'p_request_id': requestId,
        'p_reason': reason,
      });
    } catch (_) {
      throw const StaffLeaveRequestRepositoryException(
        'İzin talebi reddedilemedi.',
      );
    }
  }
}
