import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_access_gate.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_sanitizer.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_signed_url_service.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_path_builder.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  group('PDF Storage security invariants (staging smoke regression)', () {
    test('signed URL TTL production constant is 120 seconds', () {
      expect(
        PatientFileStorageRepository.signedUrlExpiresInSeconds,
        120,
      );
      expect(
        PatientFileSignedUrlService.expiresInSeconds,
        PatientFileStorageRepository.signedUrlExpiresInSeconds,
      );
    });

    test('assistant cannot view physiotherapy scope metadata', () {
      AuthSession.setUser(
        AppUser(
          id: 'a1',
          username: 'asst',
          displayName: 'Asistan',
          role: AppRoles.assistant,
        ),
      );
      addTearDown(AuthSession.clear);

      final meta = PatientFileMetadata(
        id: 'f1',
        tenantId: 't1',
        patientId: 'p1',
        fileKind: PatientFileKind.physiotherapyDocument,
        clinicalContext: PatientFileClinicalContext.physiotherapy,
        displayName: 'FTR',
        storageBucket: PatientFileStoragePathBuilder.defaultBucket,
        storagePath: 'tenants/t1/patients/p1/files/f1/x.pdf',
        status: PatientFileStatus.active,
        visibilityScope: PatientFileVisibilityScope.physiotherapy,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(PatientFileMetadataAccessGate.canView(meta), isFalse);
    });

    test('nurse cannot upload any scope', () {
      AuthSession.setUser(
        AppUser(
          id: 'n1',
          username: 'nurse',
          displayName: 'Hemşire',
          role: AppRoles.nurse,
        ),
      );
      addTearDown(AuthSession.clear);

      expect(
        PatientFileMetadataAccessGate.canUploadForScope(
          PatientFileVisibilityScope.clinicOperations,
        ),
        isFalse,
      );
    });

    test('sanitizer blocks signed_url and clinical_data keys', () {
      final out = PatientFileMetadataSanitizer.sanitize({
        'signed_url': 'https://leak.example',
        'public_url': 'https://public.example',
        'fileContent': 'bytes',
        'clinical_data': {'x': 1},
        'internal_doctor_note': 'secret',
        'template_key': 'ok',
      });
      expect(out.keys, ['template_key']);
    });

    test('default provider uses mock storage in unit test env', () {
      expect(
        PatientFileStorageRepositoryProvider.repository,
        isA<MockPatientFileStorageRepository>(),
      );
    });
  });
}
