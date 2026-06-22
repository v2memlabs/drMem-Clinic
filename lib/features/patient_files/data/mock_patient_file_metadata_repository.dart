import '../../files/data/mock_patient_files.dart';
import '../../files/models/patient_file.dart';
import '../models/patient_file_metadata.dart';
import 'mock_patient_file_metadata_mapper.dart';
import 'patient_file_metadata_create_input.dart';
import 'patient_file_metadata_repository.dart';

/// Mock hasta dosya metadata — in-memory legacy [mockPatientFiles].
class MockPatientFileMetadataRepository implements PatientFileMetadataRepository {
  static final Set<String> _archivedIds = {};

  @override
  Future<List<PatientFileMetadata>> listPatientFiles({
    required String patientId,
  }) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    final list = mockPatientFiles
        .where((f) => f.patientId == pid && !_archivedIds.contains(f.id))
        .map(MockPatientFileMetadataMapper.fromLegacyFile)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List<PatientFileMetadata>.from(list);
  }

  @override
  Future<List<PatientFileMetadata>> listTenantFiles({
    String? patientId,
  }) async {
    final pid = patientId?.trim() ?? '';
    if (pid.isNotEmpty) {
      return listPatientFiles(patientId: pid);
    }

    final list = mockPatientFiles
        .where((f) => !_archivedIds.contains(f.id))
        .map(MockPatientFileMetadataMapper.fromLegacyFile)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List<PatientFileMetadata>.from(list);
  }

  @override
  Future<PatientFileMetadata?> getPatientFileMetadata(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty || _archivedIds.contains(id)) return null;

    for (final file in mockPatientFiles) {
      if (file.id == id) {
        return MockPatientFileMetadataMapper.fromLegacyFile(file);
      }
    }
    return null;
  }

  @override
  Future<PatientFileMetadata> createPatientFileMetadata(
    PatientFileMetadataCreateInput input,
  ) async {
    final legacy = MockPatientFileMetadataMapper.toLegacyFile(input);
    addMockPatientFile(legacy);
    return MockPatientFileMetadataMapper.fromLegacyFile(legacy);
  }

  @override
  Future<void> archivePatientFile(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty) return;
    _archivedIds.add(id);
  }

  @override
  Future<List<PatientFileMetadata>> listEncounterFiles({
    required String encounterId,
  }) async =>
      const [];

  @override
  Future<List<PatientFileMetadata>> listAppointmentFiles({
    required String appointmentId,
  }) async =>
      const [];
}
