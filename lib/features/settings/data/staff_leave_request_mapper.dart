import '../models/staff_leave_record.dart';
import '../models/staff_leave_request.dart';
import 'staff_leave_note_sanitizer.dart';
import 'staff_leave_record_mapper.dart';

abstract final class StaffLeaveRequestMapper {
  static StaffLeaveRequest fromRow(Map<String, dynamic> row) {
    return fromMap(Map<String, dynamic>.from(row));
  }

  static StaffLeaveRequest fromJson(Map<String, dynamic> json) {
    return fromMap(json);
  }

  static Map<String, dynamic> toJson(StaffLeaveRequest request) {
    return {
      'id': request.id,
      'requester_profile_id': request.requesterProfileId,
      'staff_display_name': request.staffDisplayName,
      'role_label': request.roleLabel,
      'leave_type': request.leaveType.dbValue,
      'starts_at': request.startsAt.toUtc().toIso8601String(),
      'ends_at': request.endsAt.toUtc().toIso8601String(),
      'note': request.note,
      'status': request.status.dbValue,
      'reviewed_by': request.reviewedByProfileId,
      'reviewed_at': request.reviewedAt?.toUtc().toIso8601String(),
      'rejection_reason': request.rejectionReason,
      'leave_record_id': request.leaveRecordId,
      'created_at': request.createdAt.toUtc().toIso8601String(),
      'updated_at': request.updatedAt.toUtc().toIso8601String(),
    };
  }

  static void validateDraft(
    StaffLeaveRequestDraft draft, {
    required String staffDisplayName,
    String? roleLabel,
  }) {
    StaffLeaveRecordMapper.validateDraft(
      StaffLeaveDraft(
        staffDisplayName: staffDisplayName,
        roleLabel: roleLabel,
        leaveType: draft.leaveType,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        note: draft.note,
      ),
    );
  }

  static Map<String, dynamic> draftToInsertPayload({
    required String tenantId,
    required String requesterProfileId,
    required String staffDisplayName,
    String? roleLabel,
    required StaffLeaveRequestDraft draft,
  }) {
    StaffLeaveRecordMapper.validateDraft(
      StaffLeaveDraft(
        staffDisplayName: staffDisplayName,
        roleLabel: roleLabel,
        leaveType: draft.leaveType,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        note: draft.note,
      ),
    );

    return {
      'tenant_id': tenantId,
      'requester_profile_id': requesterProfileId,
      'staff_display_name': staffDisplayName.trim(),
      'role_label': (roleLabel == null || roleLabel.trim().isEmpty)
          ? null
          : roleLabel.trim(),
      'leave_type': draft.leaveType.dbValue,
      'starts_at': draft.startsAt.toUtc().toIso8601String(),
      'ends_at': draft.endsAt.toUtc().toIso8601String(),
      'note': StaffLeaveNoteSanitizer.sanitize(draft.note),
      'status': StaffLeaveRequestStatus.pending.dbValue,
    };
  }

  static StaffLeaveRequest fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const StaffLeaveRecordValidationException('Talep kimliği eksik.');
    }

    final startsAt = DateTime.tryParse(map['starts_at']?.toString() ?? '');
    final endsAt = DateTime.tryParse(map['ends_at']?.toString() ?? '');
    if (startsAt == null || endsAt == null) {
      throw const StaffLeaveRecordValidationException('Tarih alanları geçersiz.');
    }

    final createdAt =
        DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();
    final updatedAt =
        DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? createdAt;

    return StaffLeaveRequest(
      id: id,
      requesterProfileId: map['requester_profile_id']?.toString() ?? '',
      staffDisplayName: map['staff_display_name']?.toString() ?? '',
      roleLabel: map['role_label']?.toString(),
      leaveType: StaffLeaveTypeLabels.fromDb(map['leave_type']?.toString()),
      startsAt: startsAt,
      endsAt: endsAt,
      note: StaffLeaveNoteSanitizer.sanitize(map['note']?.toString()),
      status: StaffLeaveRequestStatusLabels.fromDb(map['status']?.toString()),
      reviewedByProfileId: map['reviewed_by']?.toString(),
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'].toString())
          : null,
      rejectionReason: map['rejection_reason']?.toString(),
      leaveRecordId: map['leave_record_id']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
