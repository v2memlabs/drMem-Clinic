import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/staff_leave_record.dart';
import 'staff_leave_record_mapper.dart';
import 'staff_leave_record_repository.dart';

class SupabaseStaffLeaveRecordRepository implements StaffLeaveRecordRepository {
  SupabaseStaffLeaveRecordRepository(this._client);

  factory SupabaseStaffLeaveRecordRepository.fromSupabase() {
    return SupabaseStaffLeaveRecordRepository(Supabase.instance.client);
  }

  static const String table = 'staff_leave_records';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const StaffLeaveRecordRepositoryException(
        'Supabase yapılandırması hazır değil.',
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const StaffLeaveRecordRepositoryException(
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  @override
  Future<List<StaffLeaveRecord>> listActiveForCalendarDay(
    DateTime calendarDay,
  ) async {
    _requireTenantId();
    final dayStart = DateTime(
      calendarDay.year,
      calendarDay.month,
      calendarDay.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    try {
      final rows = await _client
          .from(table)
          .select()
          .eq('status', StaffLeaveStatus.active.dbValue)
          .lt('starts_at', dayEnd.toUtc().toIso8601String())
          .gt('ends_at', dayStart.toUtc().toIso8601String())
          .order('starts_at', ascending: true);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(StaffLeaveRecordMapper.fromRow)
          .toList();
    } catch (_) {
      throw const StaffLeaveRecordRepositoryException(
        'Personel izin kayıtları yüklenemedi.',
      );
    }
  }

  @override
  Future<List<StaffLeaveRecord>> list() async {
    _requireTenantId();
    try {
      final rows = await _client
          .from(table)
          .select()
          .order('starts_at', ascending: false);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(StaffLeaveRecordMapper.fromRow)
          .toList();
    } catch (_) {
      throw const StaffLeaveRecordRepositoryException(
        'Personel izin kayıtları yüklenemedi.',
      );
    }
  }

  @override
  Future<StaffLeaveRecord?> getById(String id) async {
    _requireTenantId();
    try {
      final row = await _client.from(table).select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return StaffLeaveRecordMapper.fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      throw const StaffLeaveRecordRepositoryException(
        'İzin kaydı yüklenemedi.',
      );
    }
  }

  @override
  Future<StaffLeaveRecord> create(StaffLeaveDraft draft) async {
    final tenantId = _requireTenantId();
    final payload = StaffLeaveRecordMapper.draftToInsertPayload(
      tenantId: tenantId,
      draft: draft,
      createdBy: _createdByProfileId(),
    );

    try {
      final row = await _client.from(table).insert(payload).select().single();
      return StaffLeaveRecordMapper.fromRow(Map<String, dynamic>.from(row));
    } on StaffLeaveRecordValidationException {
      rethrow;
    } catch (_) {
      throw const StaffLeaveRecordRepositoryException(
        'İzin kaydı kaydedilemedi.',
      );
    }
  }

  @override
  Future<StaffLeaveRecord> update(StaffLeaveRecord record) async {
    _requireTenantId();
    final payload = StaffLeaveRecordMapper.recordToUpdatePayload(record);

    try {
      final row = await _client
          .from(table)
          .update(payload)
          .eq('id', record.id)
          .select()
          .single();
      return StaffLeaveRecordMapper.fromRow(Map<String, dynamic>.from(row));
    } on StaffLeaveRecordValidationException {
      rethrow;
    } catch (_) {
      throw const StaffLeaveRecordRepositoryException(
        'İzin kaydı güncellenemedi.',
      );
    }
  }

  @override
  Future<void> cancel(String id) async {
    _requireTenantId();
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _client.from(table).update({
        'status': StaffLeaveStatus.cancelled.dbValue,
        'cancelled_at': now,
        'updated_at': now,
      }).eq('id', id);
    } catch (_) {
      throw const StaffLeaveRecordRepositoryException(
        'İzin kaydı iptal edilemedi.',
      );
    }
  }
}
