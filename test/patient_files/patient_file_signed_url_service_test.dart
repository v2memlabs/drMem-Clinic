import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_signed_url_service.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _MetaRepo implements PatientFileMetadataRepository {
  _MetaRepo(this.file);

  final PatientFileMetadata? file;

  @override
  Future<PatientFileMetadata?> getPatientFileMetadata(String fileId) async =>
      file?.id == fileId ? file : null;

  @override
  Future<PatientFileMetadata> createPatientFileMetadata(input) async =>
      throw UnimplementedError();

  @override
  Future<void> archivePatientFile(String fileId) async {}

  @override
  Future<List<PatientFileMetadata>> listAppointmentFiles({
    required String appointmentId,
  }) async =>
      [];

  @override
  Future<List<PatientFileMetadata>> listEncounterFiles({
    required String encounterId,
  }) async =>
      [];

  @override
  Future<List<PatientFileMetadata>> listPatientFiles({
    required String patientId,
  }) async =>
      [];
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    MockPatientFileStorageRepository.clearAll();
    PatientFileMetadataRepositoryProvider.testOverride = null;
    PatientFileStorageRepositoryProvider.testOverride = null;
  });

  PatientFileMetadata clinicFile() => PatientFileMetadata(
        id: 'f1',
        tenantId: 't1',
        patientId: 'p1',
        fileKind: PatientFileKind.patientUpload,
        clinicalContext: PatientFileClinicalContext.patient,
        displayName: 'Dosya',
        storageBucket: 'patient-files-private',
        storagePath: 'tenants/t1/patients/p1/files/f1/doc.pdf',
        status: PatientFileStatus.active,
        visibilityScope: PatientFileVisibilityScope.clinicOperations,
        createdAt: DateTime(2026, 1, 1),
      );

  test('signed url uses 120 second ttl', () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'a',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 't1', name: 'Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 't1',
          userId: 'u1',
          role: 'assistant_secretary',
        ),
        profile: const UserProfile(userId: 'u1', displayName: 'A'),
      ),
    );

    final storage = MockPatientFileStorageRepository();
    PatientFileStorageRepositoryProvider.testOverride = storage;
    PatientFileMetadataRepositoryProvider.testOverride =
        _MetaRepo(clinicFile());

    await storage.upload(
      bucket: 'patient-files-private',
      path: 'tenants/t1/patients/p1/files/f1/doc.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'application/pdf',
    );

    final url = await PatientFileSignedUrlService.createViewUrlForPatientFile(
      'f1',
    );
    expect(url, contains('ttl=120'));
    expect(url, isNot(contains('storage_path')));
  });

  test('unauthorized scope does not return signed url', () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'a',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final base = clinicFile();
    final physioOnly = PatientFileMetadata(
      id: base.id,
      tenantId: base.tenantId,
      patientId: base.patientId,
      fileKind: base.fileKind,
      clinicalContext: base.clinicalContext,
      displayName: base.displayName,
      storageBucket: base.storageBucket,
      storagePath: base.storagePath,
      status: base.status,
      visibilityScope: PatientFileVisibilityScope.physiotherapy,
      createdAt: base.createdAt,
    );

    PatientFileMetadataRepositoryProvider.testOverride = _MetaRepo(physioOnly);
    PatientFileStorageRepositoryProvider.testOverride =
        MockPatientFileStorageRepository();

    expect(
      () => PatientFileSignedUrlService.createViewUrlForPatientFile('f1'),
      throwsA(isA<PatientFileSignedUrlException>()),
    );
  });
}
