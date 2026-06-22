import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../settings/settings_product_labels.dart';
import '../models/staff_leave_record.dart';
import '../models/staff_leave_request.dart';
import 'staff_leave_record_repository_provider.dart';
import 'staff_leave_request_mapper.dart';
import 'staff_leave_request_repository.dart';

class MockStaffLeaveRequestRepository implements StaffLeaveRequestRepository {
  static final Map<String, String> _memoryByTenant = {};
  static int _idCounter = 0;

  static String storageKeyForTenant(String tenantId) =>
      'staff_leave_requests_$tenantId';

  static bool _prefsPrimed = false;

  static void _primePrefsForMockBackend() {
    if (!AppBackendConfig.isMock || _prefsPrimed) return;
    _prefsPrimed = true;
    try {
      SharedPreferences.setMockInitialValues({});
    } catch (_) {}
  }

  String _requireTenantId() {
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const StaffLeaveRequestRepositoryException(
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  String _requireProfileId() {
    final ctx = ActiveTenantContextStore.current;
    final fromCtx = ctx?.profile.userId;
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

  Future<List<StaffLeaveRequest>> _readAll() async {
    final tenantId = _requireTenantId();
    final key = storageKeyForTenant(tenantId);
    final cached = _memoryByTenant[key];
    final raw = cached ?? await _readRaw(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => StaffLeaveRequestMapper.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> _readRaw(String key) async {
    _primePrefsForMockBackend();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _writeAll(List<StaffLeaveRequest> requests) async {
    final tenantId = _requireTenantId();
    final key = storageKeyForTenant(tenantId);
    final json = jsonEncode(requests.map(StaffLeaveRequestMapper.toJson).toList());
    _memoryByTenant[key] = json;
    _primePrefsForMockBackend();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json);
  }

  @override
  Future<List<StaffLeaveRequest>> listMine() async {
    final profileId = _requireProfileId();
    final all = await _readAll();
    return all
        .where((r) => r.requesterProfileId == profileId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<StaffLeaveRequest>> listPending() async {
    final all = await _readAll();
    return all
        .where((r) => r.isPending)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<int> countPending() async {
    final pending = await listPending();
    return pending.length;
  }

  @override
  Future<StaffLeaveRequest> create(StaffLeaveRequestDraft draft) async {
    final now = DateTime.now();
    final request = StaffLeaveRequest(
      id: 'slr_${++_idCounter}_${now.millisecondsSinceEpoch}',
      requesterProfileId: _requireProfileId(),
      staffDisplayName: _staffDisplayName(),
      roleLabel: _roleLabel(),
      leaveType: draft.leaveType,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      note: draft.note,
      status: StaffLeaveRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final all = await _readAll();
    all.add(request);
    await _writeAll(all);
    return request;
  }

  @override
  Future<void> approve(String requestId) async {
    final all = await _readAll();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index < 0) {
      throw const StaffLeaveRequestRepositoryException('Talep bulunamadı.');
    }
    final req = all[index];
    if (!req.isPending) {
      throw const StaffLeaveRequestRepositoryException(
        'Talep zaten işlenmiş.',
      );
    }

    final record = await StaffLeaveRecordRepositoryProvider.repository.create(
      StaffLeaveDraft(
        staffDisplayName: req.staffDisplayName,
        roleLabel: req.roleLabel,
        leaveType: req.leaveType,
        startsAt: req.startsAt,
        endsAt: req.endsAt,
        note: req.note,
      ),
    );

    final now = DateTime.now();
    all[index] = StaffLeaveRequest(
      id: req.id,
      requesterProfileId: req.requesterProfileId,
      staffDisplayName: req.staffDisplayName,
      roleLabel: req.roleLabel,
      leaveType: req.leaveType,
      startsAt: req.startsAt,
      endsAt: req.endsAt,
      note: req.note,
      status: StaffLeaveRequestStatus.approved,
      reviewedByProfileId: _requireProfileId(),
      reviewedAt: now,
      leaveRecordId: record.id,
      createdAt: req.createdAt,
      updatedAt: now,
    );
    await _writeAll(all);
  }

  @override
  Future<void> reject(String requestId, {String? reason}) async {
    final all = await _readAll();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index < 0) {
      throw const StaffLeaveRequestRepositoryException('Talep bulunamadı.');
    }
    final req = all[index];
    if (!req.isPending) {
      throw const StaffLeaveRequestRepositoryException(
        'Talep zaten işlenmiş.',
      );
    }

    final now = DateTime.now();
    all[index] = StaffLeaveRequest(
      id: req.id,
      requesterProfileId: req.requesterProfileId,
      staffDisplayName: req.staffDisplayName,
      roleLabel: req.roleLabel,
      leaveType: req.leaveType,
      startsAt: req.startsAt,
      endsAt: req.endsAt,
      note: req.note,
      status: StaffLeaveRequestStatus.rejected,
      reviewedByProfileId: _requireProfileId(),
      reviewedAt: now,
      rejectionReason: reason?.trim().isEmpty ?? true ? null : reason!.trim(),
      createdAt: req.createdAt,
      updatedAt: now,
    );
    await _writeAll(all);
  }
}
