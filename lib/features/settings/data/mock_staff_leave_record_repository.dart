import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/staff_leave_record.dart';
import 'staff_leave_note_sanitizer.dart';
import 'staff_leave_record_mapper.dart';
import 'staff_leave_record_repository.dart';

/// Mock persistence — SharedPreferences `staff_leave_{tenantId}`.
class MockStaffLeaveRecordRepository implements StaffLeaveRecordRepository {
  static final Map<String, String> _memoryByTenant = {};
  static int _idCounter = 0;

  static String storageKeyForTenant(String tenantId) => 'staff_leave_$tenantId';

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
      throw const StaffLeaveRecordRepositoryException(
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  Future<List<StaffLeaveRecord>> _readAll() async {
    final tenantId = _requireTenantId();
    final key = storageKeyForTenant(tenantId);
    final cached = _memoryByTenant[key];
    final raw = cached ?? await _readRaw(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final records = <StaffLeaveRecord>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          records.add(StaffLeaveRecordMapper.fromJson(item));
        } catch (_) {
          continue;
        }
      }
      records.sort((a, b) => b.startsAt.compareTo(a.startsAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<String?> _readRaw(String key) async {
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

  Future<void> _writeAll(List<StaffLeaveRecord> records) async {
    final tenantId = _requireTenantId();
    final key = storageKeyForTenant(tenantId);
    final json = jsonEncode(records.map(StaffLeaveRecordMapper.toJson).toList());
    _memoryByTenant[key] = json;

    _primePrefsForMockBackend();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json);
    } catch (_) {
      // Test / kanal yok — bellek önbelleği yeterli.
    }
  }

  static String _newId() {
    _idCounter++;
    return 'mock-sl-${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
  }

  @override
  Future<List<StaffLeaveRecord>> list() => _readAll();

  @override
  Future<List<StaffLeaveRecord>> listActiveForCalendarDay(
    DateTime calendarDay,
  ) async {
    final dayStart = DateTime(
      calendarDay.year,
      calendarDay.month,
      calendarDay.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final all = await _readAll();
    return all
        .where((r) {
          if (!r.isActive) return false;
          final start = r.startsAt.toLocal();
          final end = r.endsAt.toLocal();
          return end.isAfter(dayStart) && start.isBefore(dayEnd);
        })
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<StaffLeaveRecord?> getById(String id) async {
    final all = await _readAll();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<StaffLeaveRecord> create(StaffLeaveDraft draft) async {
    StaffLeaveRecordMapper.validateDraft(draft);
    final now = DateTime.now();
    final record = StaffLeaveRecord(
      id: _newId(),
      staffDisplayName: draft.staffDisplayName.trim(),
      roleLabel: draft.roleLabel?.trim().isEmpty == true
          ? null
          : draft.roleLabel?.trim(),
      leaveType: draft.leaveType,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      note: StaffLeaveNoteSanitizer.sanitize(draft.note),
      status: StaffLeaveStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    final all = await _readAll();
    all.insert(0, record);
    await _writeAll(all);
    return record;
  }

  @override
  Future<StaffLeaveRecord> update(StaffLeaveRecord record) async {
    StaffLeaveRecordMapper.validateRecord(record);
    final all = await _readAll();
    final index = all.indexWhere((r) => r.id == record.id);
    if (index < 0) {
      throw const StaffLeaveRecordRepositoryException('İzin kaydı bulunamadı.');
    }
    final updated = record.copyWith(updatedAt: DateTime.now());
    all[index] = updated;
    await _writeAll(all);
    return updated;
  }

  @override
  Future<void> cancel(String id) async {
    final all = await _readAll();
    final index = all.indexWhere((r) => r.id == id);
    if (index < 0) {
      throw const StaffLeaveRecordRepositoryException('İzin kaydı bulunamadı.');
    }
    final now = DateTime.now();
    all[index] = all[index].copyWith(
      status: StaffLeaveStatus.cancelled,
      updatedAt: now,
      cancelledAt: now,
    );
    await _writeAll(all);
  }
}
