import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_provider.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_create_input.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_upload_orchestrator.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _TrackingStorage extends MockPatientFileStorageRepository {
  int removeCalls = 0;

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {
    removeCalls++;
    await super.remove(bucket: bucket, path: path);
  }
}

class _FakeMetadataRepo implements PatientFileMetadataRepository {
  _FakeMetadataRepo({this.failCreate = false});

  bool failCreate;
  int createCount = 0;
  PatientFileMetadataCreateInput? lastInput;

  @override
  Future<PatientFileMetadata> createPatientFileMetadata(
    PatientFileMetadataCreateInput input,
  ) async {
    createCount++;
    lastInput = input;
    if (failCreate) throw Exception('fail');
    return PatientFileMetadata(
      id: 'meta-1',
      tenantId: 'tenant-a',
      patientId: input.patientId,
      fileKind: input.fileKind,
      clinicalContext: input.clinicalContext,
      displayName: input.displayName,
      storageBucket: input.storageBucket,
      storagePath: input.storagePath,
      status: PatientFileStatus.active,
      visibilityScope: input.visibilityScope,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> archivePatientFile(String fileId) async {}

  @override
  Future<PatientFileMetadata?> getPatientFileMetadata(String fileId) async =>
      null;

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

  ActiveTenantContext tenant() => ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-a', name: 'Test'),
        membership: const Membership(
          id: 'm1',
          tenantId: 'tenant-a',
          userId: 'u1',
          role: 'doctor_admin',
        ),
        profile: const UserProfile(userId: 'u1', displayName: 'Dr'),
      );

  group('PatientFileUploadOrchestrator', () {
    test('upload success creates metadata after storage', () async {
      AuthSession.setUser(
        AppUser(
          id: 'u1',
          username: 'doc',
          displayName: 'Dr',
          role: AppRoles.doctor,
        ),
      );
      ActiveTenantContextStore.set(tenant());

      final storage = MockPatientFileStorageRepository();
      final metadata = _FakeMetadataRepo();
      PatientFileStorageRepositoryProvider.testOverride = storage;
      PatientFileMetadataRepositoryProvider.testOverride = metadata;

      await PatientFileUploadOrchestrator.uploadPatientFile(
        patientId: 'patient-1',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'application/pdf',
        originalFileName: 'rapor.pdf',
      );

      expect(metadata.createCount, 1);
      expect(MockPatientFileStorageRepository.pathToBytes, isNotEmpty);
      expect(metadata.lastInput?.patientId, 'patient-1');
    });

    test('metadata fail triggers storage remove', () async {
      MockPatientFileStorageRepository.clearAll();
      AuthSession.setUser(
        AppUser(
          id: 'u1',
          username: 'doc',
          displayName: 'Dr',
          role: AppRoles.doctor,
        ),
      );
      ActiveTenantContextStore.set(tenant());

      final storage = _TrackingStorage();
      PatientFileStorageRepositoryProvider.testOverride = storage;
      PatientFileMetadataRepositoryProvider.testOverride =
          _FakeMetadataRepo(failCreate: true);

      await expectLater(
        PatientFileUploadOrchestrator.uploadPatientFile(
          patientId: 'patient-1',
          bytes: Uint8List.fromList([9]),
          mimeType: 'application/pdf',
          originalFileName: 'x.pdf',
        ),
        throwsA(isA<PatientFileUploadException>()),
      );

      expect(storage.removeCalls, 1);
      expect(MockPatientFileStorageRepository.pathToBytes, isEmpty);
    });

    test('no tenant fails safely', () async {
      AuthSession.setUser(
        AppUser(
          id: 'u1',
          username: 'doc',
          displayName: 'Dr',
          role: AppRoles.doctor,
        ),
      );

      await expectLater(
        PatientFileUploadOrchestrator.uploadPatientFile(
          patientId: 'patient-1',
          bytes: Uint8List.fromList([1]),
          mimeType: 'application/pdf',
          originalFileName: 'a.pdf',
        ),
        throwsA(isA<PatientFileUploadException>()),
      );
    });
  });
}
