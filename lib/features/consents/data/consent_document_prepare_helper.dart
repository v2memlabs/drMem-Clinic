import '../../../core/auth/auth_session.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/repository_registry.dart';
import '../../patients/models/patient.dart';
import '../../pdf_outputs/data/pdf_output_list_user_messages.dart';
import '../../pdf_outputs/data/pdf_output_repository_failure.dart';
import '../../pdf_outputs/data/pdf_output_storage_orchestrator.dart';
import '../../pdf_outputs/models/pdf_output.dart';
import '../models/consent_record.dart';
import '../models/consent_signature_mode.dart';
import '../models/consent_template.dart';
import '../services/consent_document_pdf_generator.dart';
import 'consent_gate_session_store.dart';
import 'consent_list_refresh.dart';
import 'consent_list_user_messages.dart';
import 'consent_repository_failure.dart';
import 'consent_repository_provider.dart';
import 'consent_template_prepare_data_source.dart';

/// Onam evrakı — PDF üretimi + consent/PDF persist (form ve şablon hazırlama).
abstract final class ConsentDocumentPrepareHelper {
  static String? validateRemoteReady() {
    if (!AppBackendConfig.isSupabase) return null;
    if (!ConsentRepositoryProvider.usesRemoteConsents) {
      return ConsentListUserMessages.forFailure(
        ConsentRepositoryFailure.notConfigured,
      );
    }
    if (!PdfOutputStorageOrchestrator.isRemoteStorageReady) {
      return 'PDF kayıt altyapısı henüz kullanıma hazır değil.';
    }
    return null;
  }

  static PdfOutput buildPdfDraft({
    required ConsentTemplate template,
    required String recordId,
    required String patientId,
    required String patientName,
    required String recordedBy,
    String extraNotes = '',
  }) {
    final summaryLines = <String>[
      'Onam türü: ${consentTypeLabel(consentTypeFromTemplateCategory(template.category))}',
      'Şablon: ${template.title} (${template.version})',
      'Onam kaydı: $recordId',
      if (extraNotes.isNotEmpty) 'Ek not: $extraNotes',
    ];

    return PdfOutput(
      id: 'pdf${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      patientName: patientName,
      createdAt: DateTime.now(),
      documentType: DocumentType.onamFormu,
      title: 'Onam Formu — ${template.title}',
      relatedDiagnosis: template.category,
      relatedTreatmentPlan: template.title,
      contentSummary: summaryLines.join('\n'),
      warningNote:
          'Bu evrak hasta onam süreci için hazırlanmıştır. Islak imza sonrası hasta dosyasında saklanmalıdır.',
      createdBy: recordedBy,
      status: PdfStatus.hazirlandi,
      sourceModule: pdfSourceModuleConsentTemplate,
      sourceRecordId: recordId,
    );
  }

  static Future<ConsentTemplatePrepareSaveResult> saveGeneratedDocument({
    required ConsentTemplate template,
    required Patient patient,
    required ConsentRecord consent,
    required String recordedBy,
    required DateTime preparedAt,
    String extraNotes = '',
  }) async {
    final remoteError = validateRemoteReady();
    if (remoteError != null) {
      return ConsentTemplatePrepareSaveResult.failure(remoteError);
    }

    if (!AuthSession.canEditPdfOutputs) {
      return ConsentTemplatePrepareSaveResult.failure(
        'PDF evrakı oluşturmak için yetkiniz yok.',
      );
    }

    try {
      final pendingId = consent.id.trim().isEmpty
          ? 'c${DateTime.now().millisecondsSinceEpoch}'
          : consent.id.trim();
      final pending = ConsentRecord(
        id: pendingId,
        patientId: consent.patientId,
        patientName: consent.patientName,
        createdAt: consent.createdAt,
        consentType: consent.consentType,
        status: ConsentStatus.bekliyor,
        givenAt: consent.givenAt,
        expiresAt: consent.expiresAt,
        recordedBy: consent.recordedBy,
        notes: consent.notes,
        templateId: template.id,
        templateVersion: template.version,
        appointmentId: consent.appointmentId,
        encounterId: consent.encounterId,
        signatureMode: ConsentSignatureMode.pending,
      );

      final savedConsent = await RepositoryRegistry.consentsAsync.add(pending);

      final generatedPdf = await ConsentDocumentPdfGenerator.generate(
        template: template,
        patient: patient,
        recordId: savedConsent.id,
        preparedBy: recordedBy,
        preparedAt: preparedAt,
        extraNotes: extraNotes,
      );

      final recordWithFile = ConsentRecord(
        id: savedConsent.id,
        patientId: savedConsent.patientId,
        patientName: savedConsent.patientName,
        createdAt: savedConsent.createdAt,
        consentType: savedConsent.consentType,
        status: savedConsent.status,
        givenAt: savedConsent.givenAt,
        expiresAt: savedConsent.expiresAt,
        documentFileName: generatedPdf.fileName,
        recordedBy: savedConsent.recordedBy,
        notes: savedConsent.notes,
        templateId: template.id,
        templateVersion: template.version,
        appointmentId: consent.appointmentId,
        encounterId: consent.encounterId,
      );

      await RepositoryRegistry.consentsAsync.update(recordWithFile);

      final savedPdf = await PdfOutputStorageOrchestrator.saveGeneratedPdf(
        draft: buildPdfDraft(
          template: template,
          recordId: savedConsent.id,
          patientId: consent.patientId,
          patientName: consent.patientName,
          recordedBy: recordedBy,
          extraNotes: extraNotes,
        ),
        pdfBytes: generatedPdf.bytes,
      );

      await RepositoryRegistry.consentsAsync.update(
        ConsentRecord(
          id: recordWithFile.id,
          patientId: recordWithFile.patientId,
          patientName: recordWithFile.patientName,
          createdAt: recordWithFile.createdAt,
          consentType: recordWithFile.consentType,
          status: recordWithFile.status,
          givenAt: recordWithFile.givenAt,
          expiresAt: recordWithFile.expiresAt,
          documentFileName: recordWithFile.documentFileName,
          recordedBy: recordWithFile.recordedBy,
          notes: recordWithFile.notes,
          templateId: recordWithFile.templateId,
          templateVersion: recordWithFile.templateVersion,
          pdfOutputId: savedPdf.id,
          appointmentId: recordWithFile.appointmentId,
          encounterId: recordWithFile.encounterId,
        ),
      );

      ConsentGateSessionStore.clearDismiss(consent.patientId);
      ConsentListRefresh.markStale();
      return ConsentTemplatePrepareSaveResult.ok(consentId: savedConsent.id);
    } on ConsentRepositoryException catch (e) {
      return ConsentTemplatePrepareSaveResult.failure(
        ConsentListUserMessages.forFailure(e.reason),
      );
    } on PdfOutputRepositoryException catch (e) {
      return ConsentTemplatePrepareSaveResult.failure(
        PdfOutputListUserMessages.forFailure(e.reason),
      );
    } on PdfOutputStorageException catch (e) {
      return ConsentTemplatePrepareSaveResult.failure(e.message);
    } catch (_) {
      return ConsentTemplatePrepareSaveResult.failure(
        'Onam evrakı oluşturulamadı. Lütfen tekrar deneyin.',
      );
    }
  }
}
