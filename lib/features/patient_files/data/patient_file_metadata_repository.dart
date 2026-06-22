import '../models/patient_file_metadata.dart';
import 'patient_file_metadata_create_input.dart';

/// Hasta dosya / PDF metadata — storage binary bu contract'ta yok.
abstract interface class PatientFileMetadataRepository {
  Future<List<PatientFileMetadata>> listPatientFiles({
    required String patientId,
  });

  /// Tenant geneli dosya listesi; [patientId] verilirse hasta filtresi uygulanır.
  Future<List<PatientFileMetadata>> listTenantFiles({String? patientId});

  Future<PatientFileMetadata?> getPatientFileMetadata(String fileId);

  Future<PatientFileMetadata> createPatientFileMetadata(
    PatientFileMetadataCreateInput input,
  );

  Future<void> archivePatientFile(String fileId);

  Future<List<PatientFileMetadata>> listEncounterFiles({
    required String encounterId,
  });

  Future<List<PatientFileMetadata>> listAppointmentFiles({
    required String appointmentId,
  });
}
