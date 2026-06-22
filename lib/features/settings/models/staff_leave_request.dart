import 'staff_leave_record.dart';

enum StaffLeaveRequestStatus {
  pending,
  approved,
  rejected,
}

class StaffLeaveRequest {
  final String id;
  final String requesterProfileId;
  final String staffDisplayName;
  final String? roleLabel;
  final StaffLeaveType leaveType;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? note;
  final StaffLeaveRequestStatus status;
  final String? reviewedByProfileId;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? leaveRecordId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StaffLeaveRequest({
    required this.id,
    required this.requesterProfileId,
    required this.staffDisplayName,
    this.roleLabel,
    required this.leaveType,
    required this.startsAt,
    required this.endsAt,
    this.note,
    required this.status,
    this.reviewedByProfileId,
    this.reviewedAt,
    this.rejectionReason,
    this.leaveRecordId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == StaffLeaveRequestStatus.pending;
}

class StaffLeaveRequestDraft {
  final StaffLeaveType leaveType;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? note;

  const StaffLeaveRequestDraft({
    required this.leaveType,
    required this.startsAt,
    required this.endsAt,
    this.note,
  });
}

extension StaffLeaveRequestStatusLabels on StaffLeaveRequestStatus {
  String get label {
    switch (this) {
      case StaffLeaveRequestStatus.pending:
        return 'Onay bekliyor';
      case StaffLeaveRequestStatus.approved:
        return 'Onaylandı';
      case StaffLeaveRequestStatus.rejected:
        return 'Reddedildi';
    }
  }

  static StaffLeaveRequestStatus fromDb(String? raw) {
    switch (raw) {
      case 'approved':
        return StaffLeaveRequestStatus.approved;
      case 'rejected':
        return StaffLeaveRequestStatus.rejected;
      default:
        return StaffLeaveRequestStatus.pending;
    }
  }

  String get dbValue {
    switch (this) {
      case StaffLeaveRequestStatus.pending:
        return 'pending';
      case StaffLeaveRequestStatus.approved:
        return 'approved';
      case StaffLeaveRequestStatus.rejected:
        return 'rejected';
    }
  }
}
