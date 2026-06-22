import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository.dart';
import 'package:v2mem_clinic/features/consents/data/consent_template_prepare_data_source.dart';
import 'package:v2mem_clinic/features/consents/data/mock_consent_templates.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/features/consents/models/consent_template.dart';
import 'package:v2mem_clinic/features/consents/services/consent_document_pdf_generator.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patients.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final template = mockConsentTemplates.firstWhere(
    (t) => t.category == ConsentTemplateCategories.kvkkAydinlatma,
  );
  final patient = mockPatients.first;

  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    MockPatientFileStorageRepository.clearAll();
    PatientFileStorageRepositoryProvider.testOverride = null;
  });

  void setDoctor() {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'doctor',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-a', name: 'Test Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 'tenant-a',
          userId: 'u1',
          role: 'doctor_admin',
        ),
        profile: const UserProfile(userId: 'u1', displayName: 'Dr. Test'),
      ),
    );
  }

  test('all templates use real preview text without prototype markers', () {
    for (final template in mockConsentTemplates) {
      expect(
        template.contentPreview.toLowerCase(),
        isNot(contains('prototip')),
        reason: '${template.id} still contains prototype marker',
      );
      expect(template.contentPreview.trim().length, greaterThan(80));
    }
  });

  test('surgical template generates PDF with procedure-specific body', () async {
    final template = mockConsentTemplates.firstWhere((t) => t.id == 'ct3');
    final generated = await ConsentDocumentPdfGenerator.generate(
      template: template,
      patient: patient,
      recordId: 'consent-test-surgery',
      preparedBy: 'Dr. Test',
      preparedAt: DateTime(2026, 6, 20),
    );

    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.fileName, contains('Artroskopik'));
  });
  test('generator creates real consent PDF bytes and filename', () async {
    final generated = await ConsentDocumentPdfGenerator.generate(
      template: template,
      patient: patient,
      recordId: 'consent-test-1',
      preparedBy: 'Dr. Test',
      preparedAt: DateTime(2026, 6, 20),
    );

    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.fileName, startsWith('onam_'));
    expect(generated.fileName, endsWith('.pdf'));
    expect(generated.fileName, isNot(contains('Prototip')));
  });

  test('prepare data source persists consent and generated PDF storage', () async {
    setDoctor();
    PatientFileStorageRepositoryProvider.testOverride =
        MockPatientFileStorageRepository();

    final generated = await ConsentDocumentPdfGenerator.generate(
      template: template,
      patient: patient,
      recordId: 'consent-test-2',
      preparedBy: 'Dr. Test',
      preparedAt: DateTime(2026, 6, 20),
      extraNotes: 'Hasta formu okuyarak onayladı.',
    );
    final consentBefore = ConsentRepository.instance.getAll().length;
    final pdfBefore = PdfOutputRepository.instance.getAll().length;

    final consent = ConsentRecord(
      id: 'consent-test-2',
      patientId: patient.id,
      patientName: patient.fullName,
      createdAt: DateTime(2026, 6, 20),
      consentType: ConsentType.kvkkAydinlatma,
      status: ConsentStatus.bekliyor,
      documentFileName: generated.fileName,
      recordedBy: 'Dr. Test',
      notes: 'Şablon: ${template.title} (${template.version})',
    );
    final pdfDraft = PdfOutput(
      id: 'pdf-consent-test-2',
      patientId: patient.id,
      patientName: patient.fullName,
      createdAt: DateTime(2026, 6, 20),
      documentType: DocumentType.onamFormu,
      title: 'Onam Formu - ${patient.fullName}',
      relatedDiagnosis: template.category,
      relatedTreatmentPlan: template.title,
      contentSummary: 'Onam kaydı: consent-test-2',
      warningNote: 'İmzalı nüsha hasta dosyasında saklanmalıdır.',
      createdBy: 'Dr. Test',
      status: PdfStatus.hazirlandi,
      sourceModule: pdfSourceModuleConsentTemplate,
      sourceRecordId: template.id,
    );

    final result = await ConsentTemplatePrepareDataSource.save(
      consent: consent,
      pdfDraft: pdfDraft,
      pdfBytes: generated.bytes,
    );

    expect(result.success, isTrue);
    expect(ConsentRepository.instance.getAll().length, consentBefore + 1);
    expect(PdfOutputRepository.instance.getAll().length, pdfBefore + 1);
    expect(MockPatientFileStorageRepository.pathToBytes, isNotEmpty);
    final saved = PdfOutputRepository.instance.getById('pdf-consent-test-2');
    expect(saved?.status, PdfStatus.hazirlandi);
    expect(saved?.storagePath, isNotNull);
  });
}
