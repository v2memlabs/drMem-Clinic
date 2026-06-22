import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_create_input.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';

void main() {
  test('create input sanitizes forbidden metadata keys', () {
    final input = PatientFileMetadataCreateInput(
      patientId: 'p-1',
      fileKind: PatientFileKind.patientUpload,
      clinicalContext: PatientFileClinicalContext.patient,
      displayName: 'Scan',
      storagePath: 'tenants/t/patients/p/files/f/x',
      metadata: {
        'template_key': 'ok',
        'signedUrl': 'https://x',
        'fileContent': 'bytes',
      },
    );

    expect(input.metadata.containsKey('signedUrl'), isFalse);
    expect(input.metadata.containsKey('fileContent'), isFalse);
    expect(input.metadata['template_key'], 'ok');
  });

  test('validate rejects empty required fields', () {
    final input = PatientFileMetadataCreateInput(
      patientId: '',
      fileKind: PatientFileKind.other,
      clinicalContext: PatientFileClinicalContext.patient,
      displayName: 'X',
      storagePath: 'path',
    );

    expect(input.validate, throwsArgumentError);
  });
}
