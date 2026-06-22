import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_create_input.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_failure.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_stub.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';

void main() {
  test('stub throws notConfigured without storage calls', () async {
    const stub = PatientFileMetadataRepositoryStub();

    expect(
      () => stub.listPatientFiles(patientId: 'p-1'),
      throwsA(
        isA<PatientFileMetadataRepositoryException>().having(
          (e) => e.reason,
          'reason',
          PatientFileMetadataRepositoryFailure.notConfigured,
        ),
      ),
    );

    expect(
      () => stub.createPatientFileMetadata(
        PatientFileMetadataCreateInput(
          patientId: 'p-1',
          fileKind: PatientFileKind.patientUpload,
          clinicalContext: PatientFileClinicalContext.patient,
          displayName: 'X',
          storagePath: 'path',
        ),
      ),
      throwsA(isA<PatientFileMetadataRepositoryException>()),
    );
  });
}
