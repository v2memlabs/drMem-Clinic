import '../models/patient_tag.dart';
import 'patient_tag_repository_contract.dart';

class PatientTagRepositoryStub implements PatientTagRepositoryContract {
  const PatientTagRepositoryStub();

  Never _notConfigured() => throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.notConfigured,
        'Hasta etiketleri şu anda kullanıma hazır değil.',
      );

  @override
  Future<List<PatientTag>> listAll() async => _notConfigured();

  @override
  Future<List<PatientTag>> listActive() async => _notConfigured();

  @override
  Future<PatientTag?> getById(String id) async => _notConfigured();

  @override
  Future<List<PatientTag>> getByIds(List<String> ids) async => _notConfigured();

  @override
  Future<bool> existsByName(String name) async => _notConfigured();

  @override
  Future<int> countPatientsWithTag(String tagId) async => _notConfigured();

  @override
  Future<PatientTag> create({
    required String name,
    required PatientTagColor color,
    String? description,
  }) async =>
      _notConfigured();

  @override
  Future<void> assignToPatient({
    required String patientId,
    required String tagId,
  }) async =>
      _notConfigured();

  @override
  Future<void> removeFromPatient({
    required String patientId,
    required String tagId,
  }) async =>
      _notConfigured();

  @override
  Future<List<String>> getTagIdsForPatient(String patientId) async =>
      _notConfigured();

  @override
  Future<Map<String, List<String>>> getTagIdsByPatientIds(
    List<String> patientIds,
  ) async =>
      _notConfigured();
}
