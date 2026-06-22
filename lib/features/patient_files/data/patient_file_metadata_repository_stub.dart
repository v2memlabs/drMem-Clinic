import '../models/patient_file_metadata.dart';
import 'patient_file_metadata_create_input.dart';
import 'patient_file_metadata_repository.dart';
import 'patient_file_metadata_repository_failure.dart';

/// Metadata repository — Supabase/Storage henüz bağlı değil.
class PatientFileMetadataRepositoryStub implements PatientFileMetadataRepository {
  const PatientFileMetadataRepositoryStub();

  Future<T> _notConfigured<T>() async {
    throw const PatientFileMetadataRepositoryException(
      PatientFileMetadataRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<PatientFileMetadata>> listPatientFiles({
    required String patientId,
  }) =>
      _notConfigured();

  @override
  Future<List<PatientFileMetadata>> listTenantFiles({String? patientId}) =>
      _notConfigured();

  @override
  Future<PatientFileMetadata?> getPatientFileMetadata(String fileId) =>
      _notConfigured();

  @override
  Future<PatientFileMetadata> createPatientFileMetadata(
    PatientFileMetadataCreateInput input,
  ) =>
      _notConfigured();

  @override
  Future<void> archivePatientFile(String fileId) => _notConfigured();

  @override
  Future<List<PatientFileMetadata>> listEncounterFiles({
    required String encounterId,
  }) =>
      _notConfigured();

  @override
  Future<List<PatientFileMetadata>> listAppointmentFiles({
    required String appointmentId,
  }) =>
      _notConfigured();
}

/// @deprecated Use [PatientFileMetadataRepositoryStub].
typedef SupabasePatientFileMetadataRepositoryStub =
    PatientFileMetadataRepositoryStub;
