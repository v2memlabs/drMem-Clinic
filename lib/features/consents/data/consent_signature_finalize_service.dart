import 'dart:typed_data';

import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../../patient_files/data/patient_file_upload_orchestrator.dart';
import '../../patient_files/models/patient_file_metadata.dart';
import '../../patient_files/models/patient_file_metadata_enums.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import '../../pdf_outputs/data/pdf_output_storage_orchestrator.dart';
import '../models/consent_record.dart';
import '../models/consent_signature_mode.dart';
import '../services/consent_document_pdf_generator.dart';
import '../services/consent_signed_image_to_pdf.dart';
import 'consent_gate_session_store.dart';
import 'consent_list_refresh.dart';
import 'consent_pdf_lookup_data_source.dart';
import 'consent_repository_failure.dart';
import 'consent_repository_provider.dart';
import 'consent_template_resolver.dart';

class ConsentSignatureFinalizeResult {
  final ConsentRecord? record;
  final String? errorMessage;

  const ConsentSignatureFinalizeResult._({this.record, this.errorMessage});

  factory ConsentSignatureFinalizeResult.success(ConsentRecord record) {
    return ConsentSignatureFinalizeResult._(record: record);
  }

  factory ConsentSignatureFinalizeResult.failure(String message) {
    return ConsentSignatureFinalizeResult._(errorMessage: message);
  }

  bool get success => errorMessage == null && record != null;
}

/// Pad veya ıslak imza kanıtı sonrası onamı "Alındı" yapar ve PDF'i günceller.
abstract final class ConsentSignatureFinalizeService {
  static Future<ConsentSignatureFinalizeResult> finalizeWithPadSignature({
    required ConsentRecord consent,
    required Uint8List signaturePng,
  }) async {
    if (!AuthSession.canEditConsents) {
      return ConsentSignatureFinalizeResult.failure(
        'Onam imzalama yetkiniz yok.',
      );
    }
    if (signaturePng.isEmpty) {
      return ConsentSignatureFinalizeResult.failure('İmza boş olamaz.');
    }
    if (consent.documentFileName == null ||
        consent.documentFileName!.trim().isEmpty) {
      return ConsentSignatureFinalizeResult.failure(
        'Önce onam evrakı oluşturulmalı.',
      );
    }

    final template = ConsentTemplateResolver.resolveForConsent(consent);
    if (template == null) {
      return ConsentSignatureFinalizeResult.failure(
        'Onam şablonu bulunamadı.',
      );
    }

    final patient = await PatientLookupDataSource.findById(consent.patientId);
    if (patient == null) {
      return ConsentSignatureFinalizeResult.failure('Hasta bulunamadı.');
    }

    final pdf = await ConsentPdfLookupDataSource.findPdfForConsent(consent);
    if (pdf == null || pdf.storagePath == null || pdf.storageBucket == null) {
      return ConsentSignatureFinalizeResult.failure(
        'Onam PDF evrakı bulunamadı.',
      );
    }

    final remoteError = _validateRemoteReady();
    if (remoteError != null) {
      return ConsentSignatureFinalizeResult.failure(remoteError);
    }

    final signedBy =
        AuthSession.currentUser?.displayName ?? consent.recordedBy;
    final signedAt = DateTime.now();
    final extraNotes = _extraNotesFromConsent(consent);

    try {
      final generated = await ConsentDocumentPdfGenerator.generate(
        template: template,
        patient: patient,
        recordId: consent.id,
        preparedBy: consent.recordedBy,
        preparedAt: consent.createdAt,
        extraNotes: extraNotes,
        patientSignaturePng: signaturePng,
      );

      await PdfOutputStorageOrchestrator.replaceStoredPdfBytes(
        output: pdf,
        pdfBytes: generated.bytes,
      );

      final updated = await _persistSignedConsent(
        consent: consent,
        signatureMode: ConsentSignatureMode.pad,
        signedAt: signedAt,
        signedBy: signedBy,
        documentFileName: generated.fileName,
        metadataPatch: {
          'signed_at': signedAt.toUtc().toIso8601String(),
          'signed_by': signedBy,
          'signature_mode': 'pad',
        },
      );

      return ConsentSignatureFinalizeResult.success(updated);
    } on PdfOutputStorageException catch (e) {
      return ConsentSignatureFinalizeResult.failure(e.message);
    } on ConsentRepositoryException catch (e) {
      return ConsentSignatureFinalizeResult.failure(
        _messageForConsentFailure(e.reason),
      );
    } catch (_) {
      return ConsentSignatureFinalizeResult.failure(
        'İmza kaydedilemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  static Future<ConsentSignatureFinalizeResult> finalizeWithWetUpload({
    required ConsentRecord consent,
    required Uint8List fileBytes,
    required String mimeType,
    required String originalFileName,
  }) async {
    if (!AuthSession.canEditConsents) {
      return ConsentSignatureFinalizeResult.failure(
        'Onam imzalama yetkiniz yok.',
      );
    }
    if (fileBytes.isEmpty) {
      return ConsentSignatureFinalizeResult.failure('Dosya boş olamaz.');
    }

    final pdf = await ConsentPdfLookupDataSource.findPdfForConsent(consent);
    if (pdf == null || pdf.storagePath == null || pdf.storageBucket == null) {
      return ConsentSignatureFinalizeResult.failure(
        'Onam PDF evrakı bulunamadı.',
      );
    }

    final remoteError = _validateRemoteReady();
    if (remoteError != null) {
      return ConsentSignatureFinalizeResult.failure(remoteError);
    }

    final normalizedMime = mimeType.trim().toLowerCase();
    Uint8List pdfBytes;
    String fileName;

    try {
      if (normalizedMime == 'application/pdf') {
        pdfBytes = fileBytes;
        fileName = originalFileName.trim().isEmpty
            ? 'imzali_onam.pdf'
            : originalFileName.trim();
      } else {
        pdfBytes = await ConsentSignedImageToPdf.convert(fileBytes);
        fileName = _signedPdfFileName(consent, originalFileName);
      }
    } catch (_) {
      return ConsentSignatureFinalizeResult.failure(
        'Yüklenen dosya işlenemedi.',
      );
    }

    final signedBy =
        AuthSession.currentUser?.displayName ?? consent.recordedBy;
    final signedAt = DateTime.now();

    try {
      PatientFileMetadata? uploadedFile;
      try {
        uploadedFile = await PatientFileUploadOrchestrator.uploadPatientFile(
          patientId: consent.patientId,
          bytes: fileBytes,
          mimeType: normalizedMime == 'application/pdf'
              ? 'application/pdf'
              : normalizedMime,
          originalFileName: originalFileName,
          fileKind: PatientFileKind.consentDocument,
          clinicalContext: PatientFileClinicalContext.consent,
          encounterId: consent.encounterId,
          appointmentId: consent.appointmentId,
          metadata: {
            'consent_id': consent.id,
            'signature_mode': 'wet_upload',
          },
        );
      } on PatientFileUploadException {
        // Kanıt dosyası yüklenemese bile birleşik PDF devam eder.
      }

      await PdfOutputStorageOrchestrator.replaceStoredPdfBytes(
        output: pdf,
        pdfBytes: pdfBytes,
      );

      final updated = await _persistSignedConsent(
        consent: consent,
        signatureMode: ConsentSignatureMode.wetUpload,
        signedAt: signedAt,
        signedBy: signedBy,
        documentFileName: fileName,
        metadataPatch: {
          'signed_at': signedAt.toUtc().toIso8601String(),
          'signed_by': signedBy,
          'signature_mode': 'wet_upload',
          if (uploadedFile != null) 'wet_upload_file_id': uploadedFile.id,
          'wet_upload_mime': normalizedMime,
        },
      );

      return ConsentSignatureFinalizeResult.success(updated);
    } on PdfOutputStorageException catch (e) {
      return ConsentSignatureFinalizeResult.failure(e.message);
    } on ConsentRepositoryException catch (e) {
      return ConsentSignatureFinalizeResult.failure(
        _messageForConsentFailure(e.reason),
      );
    } catch (_) {
      return ConsentSignatureFinalizeResult.failure(
        'Islak imza kaydedilemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  static Future<ConsentRecord> _persistSignedConsent({
    required ConsentRecord consent,
    required ConsentSignatureMode signatureMode,
    required DateTime signedAt,
    required String signedBy,
    required String documentFileName,
    required Map<String, Object?> metadataPatch,
  }) async {
    final metadata = Map<String, Object?>.from(consent.metadata)
      ..addAll(metadataPatch);

    final updated = ConsentRecord(
      id: consent.id,
      patientId: consent.patientId,
      patientName: consent.patientName,
      createdAt: consent.createdAt,
      consentType: consent.consentType,
      status: ConsentStatus.alindi,
      givenAt: signedAt,
      expiresAt: consent.expiresAt,
      documentFileName: documentFileName,
      recordedBy: consent.recordedBy,
      notes: consent.notes,
      templateId: consent.templateId,
      templateVersion: consent.templateVersion,
      pdfOutputId: consent.pdfOutputId,
      appointmentId: consent.appointmentId,
      encounterId: consent.encounterId,
      signatureMode: signatureMode,
      metadata: metadata,
    );

    final saved = await RepositoryRegistry.consentsAsync.update(updated);
    ConsentGateSessionStore.clearDismiss(consent.patientId);
    ConsentListRefresh.markStale();
    return saved;
  }

  static String? _validateRemoteReady() {
    if (!ConsentRepositoryProvider.usesRemoteConsents) {
      return null;
    }
    if (!PdfOutputStorageOrchestrator.isRemoteStorageReady) {
      return 'PDF kayıt altyapısı henüz kullanıma hazır değil.';
    }
    return null;
  }

  static String _extraNotesFromConsent(ConsentRecord consent) {
    final notes = consent.notes?.trim() ?? '';
    if (notes.startsWith('Şablon:')) {
      final lines = notes.split('\n');
      if (lines.length > 1) {
        return lines.sublist(1).join('\n').trim();
      }
      return '';
    }
    return notes;
  }

  static String _signedPdfFileName(
    ConsentRecord consent,
    String originalFileName,
  ) {
    final base = consent.documentFileName?.trim();
    if (base != null && base.isNotEmpty) {
      if (base.toLowerCase().endsWith('.pdf')) {
        return base.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '_imzali.pdf',
        );
      }
      return '${base}_imzali.pdf';
    }
    final stem = originalFileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return '${stem}_imzali.pdf';
  }

  static String _messageForConsentFailure(ConsentRepositoryFailure reason) {
    switch (reason) {
      case ConsentRepositoryFailure.notConfigured:
        return 'Onam servisi yapılandırılmamış.';
      case ConsentRepositoryFailure.noActiveTenant:
        return 'Aktif klinik bulunamadı.';
      case ConsentRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok. Oturumu kapatıp tekrar giriş yapmayı deneyin.';
      case ConsentRepositoryFailure.notFound:
        return 'Onam kaydı bulunamadı.';
      case ConsentRepositoryFailure.network:
        return 'Bağlantı hatası. Lütfen tekrar deneyin.';
      case ConsentRepositoryFailure.invalidRow:
        return 'Onam kaydı geçersiz.';
      case ConsentRepositoryFailure.unknown:
        return 'Onam güncellenemedi.';
    }
  }
}
