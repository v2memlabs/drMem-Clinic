import '../models/staff_leave_record.dart';

class StaffLeaveRecordRepositoryException implements Exception {
  final String message;
  const StaffLeaveRecordRepositoryException(this.message);
}

abstract class StaffLeaveRecordRepository {
  Future<List<StaffLeaveRecord>> list();

  /// Takvim günüyle çakışan aktif izin kayıtları.
  Future<List<StaffLeaveRecord>> listActiveForCalendarDay(DateTime calendarDay);

  Future<StaffLeaveRecord> create(StaffLeaveDraft draft);

  Future<StaffLeaveRecord> update(StaffLeaveRecord record);

  Future<void> cancel(String id);

  Future<StaffLeaveRecord?> getById(String id);
}
