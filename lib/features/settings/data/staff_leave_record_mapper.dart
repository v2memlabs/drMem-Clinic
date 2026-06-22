import '../models/staff_leave_record.dart';
import 'staff_leave_note_sanitizer.dart';

class StaffLeaveRecordValidationException implements Exception {
  final String message;
  const StaffLeaveRecordValidationException(this.message);
}

/// Supabase row / mock JSON ↔ [StaffLeaveRecord].
abstract final class StaffLeaveRecordMapper {
  static StaffLeaveRecord fromRow(Map<String, dynamic> row) {
    return _fromMap(row, requireId: true);
  }

  static StaffLeaveRecord fromJson(Map<String, dynamic> json) {
    return _fromMap(json, requireId: true);
  }

  static Map<String, dynamic> toJson(StaffLeaveRecord record) {
    return {
      'id': record.id,
      'staff_display_name': record.staffDisplayName,
      'role_label': record.roleLabel,
      'leave_type': record.leaveType.dbValue,
      'starts_at': record.startsAt.toUtc().toIso8601String(),
      'ends_at': record.endsAt.toUtc().toIso8601String(),
      'note': record.note,
      'status': record.status.dbValue,
      'created_at': record.createdAt.toUtc().toIso8601String(),
      'updated_at': record.updatedAt.toUtc().toIso8601String(),
      'cancelled_at': record.cancelledAt?.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> draftToInsertPayload({
    required String tenantId,
    required StaffLeaveDraft draft,
    String? createdBy,
  }) {
    validateDraft(draft);
    final now = DateTime.now().toUtc();
    return {
      'tenant_id': tenantId,
      'staff_display_name': draft.staffDisplayName.trim(),
      'role_label': _nullableTrim(draft.roleLabel),
      'leave_type': draft.leaveType.dbValue,
      'starts_at': draft.startsAt.toUtc().toIso8601String(),
      'ends_at': draft.endsAt.toUtc().toIso8601String(),
      'note': StaffLeaveNoteSanitizer.sanitize(draft.note),
      'status': StaffLeaveStatus.active.dbValue,
      'created_by': createdBy,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  static Map<String, dynamic> recordToUpdatePayload(StaffLeaveRecord record) {
    validateRecord(record);
    return {
      'staff_display_name': record.staffDisplayName.trim(),
      'role_label': _nullableTrim(record.roleLabel),
      'leave_type': record.leaveType.dbValue,
      'starts_at': record.startsAt.toUtc().toIso8601String(),
      'ends_at': record.endsAt.toUtc().toIso8601String(),
      'note': StaffLeaveNoteSanitizer.sanitize(record.note),
      'status': record.status.dbValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'cancelled_at': record.cancelledAt?.toUtc().toIso8601String(),
    };
  }

  static void validateDraft(StaffLeaveDraft draft) {
    if (draft.staffDisplayName.trim().isEmpty) {
      throw const StaffLeaveRecordValidationException(
        'Personel adı zorunludur.',
      );
    }
    if (!draft.endsAt.isAfter(draft.startsAt)) {
      throw const StaffLeaveRecordValidationException(
        'Bitiş zamanı başlangıçtan sonra olmalıdır.',
      );
    }
  }

  static void validateRecord(StaffLeaveRecord record) {
    if (record.staffDisplayName.trim().isEmpty) {
      throw const StaffLeaveRecordValidationException(
        'Personel adı zorunludur.',
      );
    }
    if (!record.endsAt.isAfter(record.startsAt)) {
      throw const StaffLeaveRecordValidationException(
        'Bitiş zamanı başlangıçtan sonra olmalıdır.',
      );
    }
  }

  static StaffLeaveRecord _fromMap(
    Map<String, dynamic> map, {
    required bool requireId,
  }) {
    final id = map['id']?.toString();
    if (requireId && (id == null || id.isEmpty)) {
      throw const StaffLeaveRecordValidationException('Kayıt kimliği eksik.');
    }

    final startsAt = _parseDateTime(map['starts_at']);
    final endsAt = _parseDateTime(map['ends_at']);
    if (startsAt == null || endsAt == null) {
      throw const StaffLeaveRecordValidationException('Tarih alanları geçersiz.');
    }

    final record = StaffLeaveRecord(
      id: id ?? '',
      staffDisplayName: map['staff_display_name']?.toString().trim() ?? '',
      roleLabel: _nullableTrim(map['role_label']?.toString()),
      leaveType: StaffLeaveTypeLabels.fromDb(map['leave_type']?.toString()),
      startsAt: startsAt,
      endsAt: endsAt,
      note: StaffLeaveNoteSanitizer.sanitize(map['note']?.toString()),
      status: StaffLeaveStatusLabels.fromDb(map['status']?.toString()),
      createdAt: _parseDateTime(map['created_at']) ?? startsAt,
      updatedAt: _parseDateTime(map['updated_at']) ?? startsAt,
      cancelledAt: _parseDateTime(map['cancelled_at']),
    );

    if (record.staffDisplayName.isEmpty) {
      throw const StaffLeaveRecordValidationException(
        'Personel adı zorunludur.',
      );
    }
    if (!record.endsAt.isAfter(record.startsAt)) {
      throw const StaffLeaveRecordValidationException(
        'Bitiş zamanı başlangıçtan sonra olmalıdır.',
      );
    }
    return record;
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
