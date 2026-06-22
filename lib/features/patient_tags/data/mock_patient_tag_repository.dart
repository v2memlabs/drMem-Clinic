import '../../patients/data/mock_patients.dart';
import '../data/mock_patient_tags.dart';
import '../models/patient_tag.dart';
import 'patient_tag_repository_contract.dart';

/// Mock — bellek içi tanımlar + mock hasta `tagIds`.
class MockPatientTagRepository implements PatientTagRepositoryContract {
  const MockPatientTagRepository();

  @override
  Future<List<PatientTag>> listAll() async {
    return List<PatientTag>.unmodifiable(mockPatientTagDefinitions);
  }

  @override
  Future<List<PatientTag>> listActive() async {
    return mockPatientTagDefinitions.where((t) => t.isActive).toList();
  }

  @override
  Future<PatientTag?> getById(String id) async {
    for (final tag in mockPatientTagDefinitions) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  @override
  Future<List<PatientTag>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final idSet = ids.toSet();
    return mockPatientTagDefinitions.where((t) => idSet.contains(t.id)).toList();
  }

  @override
  Future<bool> existsByName(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return mockPatientTagDefinitions.any(
      (t) => t.isActive && t.name.trim().toLowerCase() == normalized,
    );
  }

  @override
  Future<int> countPatientsWithTag(String tagId) async {
    var count = 0;
    for (final patient in mockPatients) {
      if (patient.tagIds.contains(tagId)) count++;
    }
    return count;
  }

  @override
  Future<PatientTag> create({
    required String name,
    required PatientTagColor color,
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 32) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.validation,
        'Etiket adı 1–32 karakter olmalıdır.',
      );
    }
    if (await existsByName(trimmed)) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.duplicateName,
        'Bu isimde aktif bir etiket zaten var.',
      );
    }
    final now = DateTime.now();
    final tag = PatientTag(
      id: 'pt${now.millisecondsSinceEpoch}',
      name: trimmed,
      color: color,
      description: description?.trim() ?? '',
      createdAt: now,
      updatedAt: now,
    );
    mockPatientTagDefinitions.insert(0, tag);
    return tag;
  }

  @override
  Future<void> assignToPatient({
    required String patientId,
    required String tagId,
  }) async {
    final index = mockPatients.indexWhere((p) => p.id == patientId);
    if (index < 0) return;
    final patient = mockPatients[index];
    if (patient.tagIds.contains(tagId)) return;
    mockPatients[index] = patient.copyWith(tagIds: [...patient.tagIds, tagId]);
  }

  @override
  Future<void> removeFromPatient({
    required String patientId,
    required String tagId,
  }) async {
    final index = mockPatients.indexWhere((p) => p.id == patientId);
    if (index < 0) return;
    final patient = mockPatients[index];
    if (!patient.tagIds.contains(tagId)) return;
    mockPatients[index] = patient.copyWith(
      tagIds: patient.tagIds.where((id) => id != tagId).toList(),
    );
  }

  @override
  Future<List<String>> getTagIdsForPatient(String patientId) async {
    final map = await getTagIdsByPatientIds([patientId]);
    return map[patientId] ?? const [];
  }

  @override
  Future<Map<String, List<String>>> getTagIdsByPatientIds(
    List<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return {};
    final idSet = patientIds.toSet();
    final result = <String, List<String>>{};
    for (final patient in mockPatients) {
      if (!idSet.contains(patient.id)) continue;
      result[patient.id] = List<String>.from(patient.tagIds);
    }
    return result;
  }
}
