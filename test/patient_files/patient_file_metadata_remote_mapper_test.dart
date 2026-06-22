import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_create_input.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_remote_mapper.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';

void main() {
  group('PatientFileMetadataRemoteMapper', () {
    test('toInsertRow sets tenant_id from scope not input', () {
      final row = PatientFileMetadataRemoteMapper.toInsertRow(
        input: PatientFileMetadataCreateInput(
          patientId: 'p-1',
          fileKind: PatientFileKind.patientUpload,
          clinicalContext: PatientFileClinicalContext.patient,
          displayName: 'Rapor',
          storagePath: 'tenants/t/patients/p/files/f/x',
          metadata: {'template_key': 'v1'},
        ),
        tenantId: 'tenant-scope',
        createdByProfileId: 'profile-1',
      );

      expect(row['tenant_id'], 'tenant-scope');
      expect(row['patient_id'], 'p-1');
      expect(row['created_by'], 'profile-1');
      expect(row['storage_bucket'], 'patient-files-private');
      expect(row['status'], 'active');
      expect(row['metadata'], {'template_key': 'v1'});
      expect(row.containsKey('signedUrl'), isFalse);
      expect(row.containsKey('fileContent'), isFalse);
      expect(row.containsKey('internal_doctor_note'), isFalse);
      expect(row.containsKey('clinical_data'), isFalse);
    });

    test('toInsertRow strips forbidden metadata keys', () {
      final row = PatientFileMetadataRemoteMapper.toInsertRow(
        input: PatientFileMetadataCreateInput(
          patientId: 'p-1',
          fileKind: PatientFileKind.other,
          clinicalContext: PatientFileClinicalContext.encounter,
          displayName: 'X',
          storagePath: 'path',
          encounterId: 'ce-1',
          metadata: {
            'pdfContent': 'bytes',
            'signed_url': 'https://x',
            'template_version': '2',
          },
        ),
        tenantId: 't-1',
      );

      final meta = row['metadata'] as Map<String, Object?>;
      expect(meta.containsKey('pdfContent'), isFalse);
      expect(meta.containsKey('signed_url'), isFalse);
      expect(meta['template_version'], '2');
    });

    test('toArchiveRow soft archives without physical delete flag', () {
      final row = PatientFileMetadataRemoteMapper.toArchiveRow(
        at: DateTime.utc(2026, 5, 25, 12),
      );

      expect(row['status'], 'archived');
      expect(row['deleted_at'], isNotNull);
      expect(row['updated_at'], isNotNull);
    });
  });
}
