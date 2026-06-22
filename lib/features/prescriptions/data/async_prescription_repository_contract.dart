import '../models/prescription.dart';

abstract interface class AsyncPrescriptionRepositoryContract {
  Future<List<Prescription>> getAll();

  Future<List<Prescription>> getByPatientId(String patientId);

  Future<Prescription?> getById(String id);

  Future<List<Prescription>> getFiltered({
    String? patientId,
    String? query,
    PrescriptionStatus? statusFilter,
  });

  Future<Prescription> create(Prescription prescription);

  Future<Prescription> update(Prescription prescription);
}
