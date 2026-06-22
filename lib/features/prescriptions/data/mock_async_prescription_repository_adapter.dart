import '../models/prescription.dart';
import 'async_prescription_repository_contract.dart';
import 'prescription_repository.dart';

class MockAsyncPrescriptionRepositoryAdapter
    implements AsyncPrescriptionRepositoryContract {
  PrescriptionRepository get _sync => PrescriptionRepository.instance;

  @override
  Future<Prescription> create(Prescription prescription) async {
    _sync.add(prescription);
    return prescription;
  }

  @override
  Future<List<Prescription>> getAll() async => _sync.getAll();

  @override
  Future<Prescription?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<Prescription>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<Prescription>> getFiltered({
    String? patientId,
    String? query,
    PrescriptionStatus? statusFilter,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      query: query,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<Prescription> update(Prescription prescription) async {
    _sync.update(prescription);
    return prescription;
  }
}
