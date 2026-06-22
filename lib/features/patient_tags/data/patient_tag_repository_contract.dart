import '../models/patient_tag.dart';

enum PatientTagRepositoryFailure {
  forbidden,
  notFound,
  validation,
  duplicateName,
  notConfigured,
  unknown,
}

class PatientTagRepositoryException implements Exception {
  const PatientTagRepositoryException(this.failure, this.message);

  final PatientTagRepositoryFailure failure;
  final String message;

  @override
  String toString() => message;
}

/// Hasta etiket tanımları ve hasta atamaları.
abstract interface class PatientTagRepositoryContract {
  Future<List<PatientTag>> listAll();

  Future<List<PatientTag>> listActive();

  Future<PatientTag?> getById(String id);

  Future<List<PatientTag>> getByIds(List<String> ids);

  Future<bool> existsByName(String name);

  Future<int> countPatientsWithTag(String tagId);

  Future<PatientTag> create({
    required String name,
    required PatientTagColor color,
    String? description,
  });

  Future<void> assignToPatient({
    required String patientId,
    required String tagId,
  });

  Future<void> removeFromPatient({
    required String patientId,
    required String tagId,
  });

  Future<List<String>> getTagIdsForPatient(String patientId);

  Future<Map<String, List<String>>> getTagIdsByPatientIds(
    List<String> patientIds,
  );
}
