import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_dto.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_mapper.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_failure.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';

void main() {
  group('PatientFileMetadataMapper', () {
    test('fromPatientFilesMap maps full row to domain enums', () {
      final domain = PatientFileMetadataMapper.fromPatientFilesMap({
        'id': 'f-1',
        'tenant_id': 't-1',
        'patient_id': 'p-1',
        'created_by_user_id': 'u-1',
        'file_kind': 'patient_upload',
        'clinical_context': 'patient',
        'physiotherapy_session_id': 'ps-1',
        'display_name': ' Rapor ',
        'original_file_name': 'rapor.pdf',
        'mime_type': 'application/pdf',
        'file_size_bytes': 1024,
        'storage_bucket': 'patient-files-private',
        'storage_path': 'tenants/t-1/patients/p-1/files/f-1/file',
        'checksum': 'abc',
        'status': 'active',
        'visibility_scope': 'clinic_operations',
        'metadata': {'template_key': 'v1', 'internal_doctor_note': 'x'},
        'created_at': '2026-05-25T10:00:00Z',
        'updated_at': '2026-05-25T11:00:00Z',
      });

      expect(domain.id, 'f-1');
      expect(domain.fileKind, PatientFileKind.patientUpload);
      expect(domain.clinicalContext, PatientFileClinicalContext.patient);
      expect(domain.physiotherapySessionId, 'ps-1');
      expect(domain.displayName, 'Rapor');
      expect(domain.fileSizeBytes, 1024);
      expect(domain.metadata.containsKey('internal_doctor_note'), isFalse);
      expect(domain.metadata['template_key'], 'v1');
      expect(domain.isGeneratedPdf, isFalse);
    });

    test('empty display_name uses safe fallback', () {
      final domain = PatientFileMetadataMapper.fromPatientFilesMap({
        'id': 'f-2',
        'tenant_id': 't-1',
        'patient_id': 'p-1',
        'clinical_context': 'patient',
        'display_name': '   ',
        'storage_path': 'tenants/t-1/patients/p-1/files/f-2/file',
        'storage_bucket': 'patient-files-private',
        'file_kind': 'other',
        'status': 'active',
        'visibility_scope': 'doctor_admin',
        'created_at': '2026-05-25T10:00:00Z',
      });

      expect(domain.displayName, PatientFileMetadataMapper.defaultDisplayName);
      expect(domain.fileKind, PatientFileKind.other);
    });

    test('fromPdfOutputsMap maps generated pdf and workflow status', () {
      final domain = PatientFileMetadataMapper.fromPdfOutputsMap({
        'id': 'pdf-1',
        'tenant_id': 't-1',
        'patient_id': 'p-1',
        'document_type': 'muayeneOzeti',
        'source_module': 'clinical_encounter',
        'source_record_id': 'ce-1',
        'storage_path': 'tenants/t-1/patients/p-1/pdf/pdf-1/document.pdf',
        'storage_bucket': 'patient-files-private',
        'file_kind': 'generated_pdf',
        'clinical_context': 'encounter',
        'visibility_scope': 'doctor_admin',
        'status': 'hazirlandi',
        'metadata': {'pdf_content': 'bytes', 'clinical_data': {}},
        'created_at': '2026-05-25T11:00:00Z',
        'updated_at': '2026-05-25T11:00:00Z',
      });

      expect(domain.isGeneratedPdf, isTrue);
      expect(domain.fileKind, PatientFileKind.generatedPdf);
      expect(domain.encounterId, 'ce-1');
      expect(domain.status, PatientFileStatus.active);
      expect(domain.metadata.containsKey('pdf_content'), isFalse);
      expect(domain.metadata.containsKey('clinical_data'), isFalse);
    });

    test('optional fields null do not crash', () {
      final domain = PatientFileMetadataMapper.fromPatientFilesMap({
        'id': 'f-3',
        'tenant_id': 't-1',
        'patient_id': 'p-1',
        'clinical_context': 'encounter',
        'display_name': 'X',
        'storage_path': 'path',
        'storage_bucket': 'patient-files-private',
        'file_kind': 'patient_upload',
        'status': 'active',
        'visibility_scope': 'clinic_operations',
        'created_at': '2026-05-25T10:00:00Z',
      });

      expect(domain.encounterId, isNull);
      expect(domain.appointmentId, isNull);
      expect(domain.physiotherapySessionId, isNull);
      expect(domain.updatedAt, isNotNull);
    });

    test('missing required id throws invalidRow', () {
      expect(
        () => PatientFileMetadataDto.fromPatientFilesRow({
          'tenant_id': 't-1',
          'patient_id': 'p-1',
          'clinical_context': 'patient',
          'display_name': 'X',
          'storage_path': 'path',
          'storage_bucket': 'b',
          'created_at': '2026-05-25T10:00:00Z',
        }),
        throwsA(
          isA<PatientFileMetadataRepositoryException>().having(
            (e) => e.reason,
            'reason',
            PatientFileMetadataRepositoryFailure.invalidRow,
          ),
        ),
      );
    });
  });
}
