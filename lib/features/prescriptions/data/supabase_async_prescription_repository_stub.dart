import '../models/prescription.dart';
import 'async_prescription_repository_contract.dart';
import 'prescription_repository_failure.dart';

class SupabaseAsyncPrescriptionRepositoryStub
    implements AsyncPrescriptionRepositoryContract {
  const SupabaseAsyncPrescriptionRepositoryStub();

  static const _error = PrescriptionRepositoryException(
    PrescriptionRepositoryFailure.notConfigured,
  );

  @override
  Future<Prescription> create(Prescription prescription) async => throw _error;

  @override
  Future<List<Prescription>> getAll() async => throw _error;

  @override
  Future<Prescription?> getById(String id) async => throw _error;

  @override
  Future<List<Prescription>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<Prescription>> getFiltered({
    String? patientId,
    String? query,
    PrescriptionStatus? statusFilter,
  }) async =>
      throw _error;

  @override
  Future<Prescription> update(Prescription prescription) async => throw _error;
}
