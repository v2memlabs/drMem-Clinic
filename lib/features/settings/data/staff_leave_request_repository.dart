import '../models/staff_leave_request.dart';

class StaffLeaveRequestRepositoryException implements Exception {
  final String message;
  const StaffLeaveRequestRepositoryException(this.message);
}

abstract class StaffLeaveRequestRepository {
  Future<List<StaffLeaveRequest>> listMine();

  Future<List<StaffLeaveRequest>> listPending();

  Future<int> countPending();

  Future<StaffLeaveRequest> create(StaffLeaveRequestDraft draft);

  Future<void> approve(String requestId);

  Future<void> reject(String requestId, {String? reason});
}
