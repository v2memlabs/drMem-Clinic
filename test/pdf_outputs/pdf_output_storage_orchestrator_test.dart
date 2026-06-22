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
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_bytes_builder.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_storage_orchestrator.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    MockPatientFileStorageRepository.clearAll();
    PatientFileStorageRepositoryProvider.testOverride = null;
  });

  PdfOutput draft() => PdfOutput(
        id: 'pdf-test-1',
        patientId: 'patient-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 5, 1),
        documentType: DocumentType.hastaBilgilendirmeFormu,
        title: 'Test PDF',
        contentSummary: 'Özet',
        warningNote: 'Not',
        createdBy: 'Dr',
        status: PdfStatus.taslak,
      );

  test('mock mode preserves PdfOutputRepository.add with storage path', () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'doc',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-a', name: 'Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 'tenant-a',
          userId: 'u1',
          role: 'doctor_admin',
        ),
        profile: const UserProfile(userId: 'u1', displayName: 'Dr'),
      ),
    );

    PatientFileStorageRepositoryProvider.testOverride =
        MockPatientFileStorageRepository();

    final before = PdfOutputRepository.instance.getAll().length;
    final draftRecord = draft();
    final pdfBytes = await PdfOutputBytesBuilder.buildForSave(draft: draftRecord);
    expect(pdfBytes, isNotNull);
    expect(pdfBytes!.isNotEmpty, isTrue);

    final saved = await PdfOutputStorageOrchestrator.saveGeneratedPdf(
      draft: draftRecord,
      pdfBytes: pdfBytes,
    );

    expect(PdfOutputRepository.instance.getAll().length, before + 1);
    expect(saved.storagePath, isNotNull);
    expect(MockPatientFileStorageRepository.pathToBytes, isNotEmpty);
  });

  test('replaceStoredPdfBytes overwrites existing mock storage object', () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'doc',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-a', name: 'Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 'tenant-a',
          userId: 'u1',
          role: 'doctor_admin',
        ),
        profile: const UserProfile(userId: 'u1', displayName: 'Dr'),
      ),
    );

    PatientFileStorageRepositoryProvider.testOverride =
        MockPatientFileStorageRepository();

    const bucket = 'patient-files-private';
    const path =
        'tenants/tenant-a/patients/patient-1/pdf/pdf-test-1/document.pdf';
    final output = PdfOutput(
      id: 'pdf-test-1',
      patientId: 'patient-1',
      patientName: 'Hasta',
      createdAt: DateTime(2026, 5, 1),
      documentType: DocumentType.onamFormu,
      title: 'Onam',
      contentSummary: 'Özet',
      warningNote: 'Not',
      createdBy: 'Dr',
      status: PdfStatus.taslak,
      storageBucket: bucket,
      storagePath: path,
    );

    await PdfOutputStorageOrchestrator.replaceStoredPdfBytes(
      output: output,
      pdfBytes: Uint8List.fromList([1, 2, 3]),
    );
    await PdfOutputStorageOrchestrator.replaceStoredPdfBytes(
      output: output,
      pdfBytes: Uint8List.fromList([4, 5, 6, 7]),
    );

    final key = '$bucket::$path';
    expect(MockPatientFileStorageRepository.pathToBytes[key], [4, 5, 6, 7]);
  });
}
