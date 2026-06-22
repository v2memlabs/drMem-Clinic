/// Personel izin kaydı — tenant-scoped; aktif kayıtlar randevu slotlarını kapatır.
class StaffLeaveRecord {
  final String id;
  final String staffDisplayName;
  final String? roleLabel;
  final StaffLeaveType leaveType;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? note;
  final StaffLeaveStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;

  const StaffLeaveRecord({
    required this.id,
    required this.staffDisplayName,
    this.roleLabel,
    required this.leaveType,
    required this.startsAt,
    required this.endsAt,
    this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
  });

  bool get isActive => status == StaffLeaveStatus.active;

  StaffLeaveRecord copyWith({
    String? staffDisplayName,
    String? roleLabel,
    StaffLeaveType? leaveType,
    DateTime? startsAt,
    DateTime? endsAt,
    String? note,
    StaffLeaveStatus? status,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    bool clearRoleLabel = false,
    bool clearNote = false,
    bool clearCancelledAt = false,
  }) {
    return StaffLeaveRecord(
      id: id,
      staffDisplayName: staffDisplayName ?? this.staffDisplayName,
      roleLabel: clearRoleLabel ? null : (roleLabel ?? this.roleLabel),
      leaveType: leaveType ?? this.leaveType,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      note: clearNote ? null : (note ?? this.note),
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt:
          clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
    );
  }
}

/// Yeni kayıt veya güncelleme taslağı.
class StaffLeaveDraft {
  final String staffDisplayName;
  final String? roleLabel;
  final StaffLeaveType leaveType;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? note;

  const StaffLeaveDraft({
    required this.staffDisplayName,
    this.roleLabel,
    required this.leaveType,
    required this.startsAt,
    required this.endsAt,
    this.note,
  });
}

enum StaffLeaveType {
  annual,
  sick,
  administrative,
  meetingTraining,
  other,
}

enum StaffLeaveStatus {
  active,
  cancelled,
}

extension StaffLeaveTypeLabels on StaffLeaveType {
  String get label {
    switch (this) {
      case StaffLeaveType.annual:
        return 'Yıllık izin';
      case StaffLeaveType.sick:
        return 'Hastalık';
      case StaffLeaveType.administrative:
        return 'İdari izin';
      case StaffLeaveType.meetingTraining:
        return 'Toplantı / Eğitim';
      case StaffLeaveType.other:
        return 'Diğer';
    }
  }

  static StaffLeaveType fromDb(String? raw) {
    switch (raw?.trim()) {
      case 'annual':
        return StaffLeaveType.annual;
      case 'sick':
        return StaffLeaveType.sick;
      case 'administrative':
        return StaffLeaveType.administrative;
      case 'meeting_training':
        return StaffLeaveType.meetingTraining;
      default:
        return StaffLeaveType.other;
    }
  }

  String get dbValue {
    switch (this) {
      case StaffLeaveType.annual:
        return 'annual';
      case StaffLeaveType.sick:
        return 'sick';
      case StaffLeaveType.administrative:
        return 'administrative';
      case StaffLeaveType.meetingTraining:
        return 'meeting_training';
      case StaffLeaveType.other:
        return 'other';
    }
  }
}

extension StaffLeaveStatusLabels on StaffLeaveStatus {
  String get label {
    switch (this) {
      case StaffLeaveStatus.active:
        return 'Aktif';
      case StaffLeaveStatus.cancelled:
        return 'İptal edildi';
    }
  }

  static StaffLeaveStatus fromDb(String? raw) {
    if (raw?.trim() == 'cancelled') {
      return StaffLeaveStatus.cancelled;
    }
    return StaffLeaveStatus.active;
  }

  String get dbValue =>
      this == StaffLeaveStatus.cancelled ? 'cancelled' : 'active';
}
