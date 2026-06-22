import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/settings/data/staff_leave_record_mapper.dart';
import 'package:v2mem_clinic/features/settings/models/staff_leave_record.dart';

void main() {
  final starts = DateTime(2026, 6, 1, 9, 0);
  final ends = DateTime(2026, 6, 3, 18, 0);

  Map<String, dynamic> validRow({
    String leaveType = 'annual',
    String status = 'active',
  }) {
    return {
      'id': 'sl-1',
      'staff_display_name': 'Dr. Test',
      'role_label': 'Doktor',
      'leave_type': leaveType,
      'starts_at': starts.toUtc().toIso8601String(),
      'ends_at': ends.toUtc().toIso8601String(),
      'note': 'Tatil',
      'status': status,
      'created_at': starts.toUtc().toIso8601String(),
      'updated_at': starts.toUtc().toIso8601String(),
      'cancelled_at': null,
    };
  }

  group('StaffLeaveRecordMapper', () {
    test('parses valid row', () {
      final record = StaffLeaveRecordMapper.fromRow(validRow());
      expect(record.id, 'sl-1');
      expect(record.staffDisplayName, 'Dr. Test');
      expect(record.leaveType, StaffLeaveType.annual);
      expect(record.status, StaffLeaveStatus.active);
      expect(record.endsAt.isAfter(record.startsAt), isTrue);
    });

    test('invalid leave_type falls back to other', () {
      final record =
          StaffLeaveRecordMapper.fromRow(validRow(leaveType: 'unknown_type'));
      expect(record.leaveType, StaffLeaveType.other);
    });

    test('invalid status falls back to active', () {
      final record =
          StaffLeaveRecordMapper.fromRow(validRow(status: 'bogus'));
      expect(record.status, StaffLeaveStatus.active);
    });

    test('cancelled status and cancelled_at', () {
      final cancelledAt = DateTime(2026, 6, 4, 10, 0);
      final row = validRow(status: 'cancelled');
      row['cancelled_at'] = cancelledAt.toUtc().toIso8601String();
      final record = StaffLeaveRecordMapper.fromRow(row);
      expect(record.status, StaffLeaveStatus.cancelled);
      expect(record.cancelledAt, isNotNull);
    });

    test('validateDraft rejects endsAt <= startsAt', () {
      expect(
        () => StaffLeaveRecordMapper.validateDraft(
          StaffLeaveDraft(
            staffDisplayName: 'Ali',
            leaveType: StaffLeaveType.sick,
            startsAt: ends,
            endsAt: starts,
          ),
        ),
        throwsA(isA<StaffLeaveRecordValidationException>()),
      );
    });

    test('validateDraft requires staff name', () {
      expect(
        () => StaffLeaveRecordMapper.validateDraft(
          StaffLeaveDraft(
            staffDisplayName: '   ',
            leaveType: StaffLeaveType.other,
            startsAt: starts,
            endsAt: ends,
          ),
        ),
        throwsA(isA<StaffLeaveRecordValidationException>()),
      );
    });

    test('toJson round-trip fields', () {
      final record = StaffLeaveRecordMapper.fromRow(validRow());
      final json = StaffLeaveRecordMapper.toJson(record);
      final again = StaffLeaveRecordMapper.fromJson(json);
      expect(again.id, record.id);
      expect(again.leaveType, record.leaveType);
      expect(again.note, record.note);
    });
  });
}
