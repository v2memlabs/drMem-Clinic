import '../models/staff_leave_record.dart';
import 'staff_leave_record_repository.dart';

class StaffLeaveRecordRepositoryStub implements StaffLeaveRecordRepository {
  const StaffLeaveRecordRepositoryStub();

  Never _notConfigured() => throw const StaffLeaveRecordRepositoryException(
        'Personel izin kayıtları şu anda kullanıma hazır değil.',
      );

  @override
  Future<List<StaffLeaveRecord>> list() async => _notConfigured();

  @override
  Future<List<StaffLeaveRecord>> listActiveForCalendarDay(
    DateTime calendarDay,
  ) async =>
      _notConfigured();

  @override
  Future<StaffLeaveRecord> create(StaffLeaveDraft draft) async =>
      _notConfigured();

  @override
  Future<StaffLeaveRecord> update(StaffLeaveRecord record) async =>
      _notConfigured();

  @override
  Future<void> cancel(String id) async => _notConfigured();

  @override
  Future<StaffLeaveRecord?> getById(String id) async => _notConfigured();
}
