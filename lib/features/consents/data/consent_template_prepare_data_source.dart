import 'dart:typed_data';

import '../../../core/data/repository_registry.dart';
import '../../pdf_outputs/data/pdf_output_list_user_messages.dart';
import '../../pdf_outputs/data/pdf_output_repository_failure.dart';
import '../../pdf_outputs/data/pdf_output_storage_orchestrator.dart';
import '../../pdf_outputs/models/pdf_output.dart';
import '../models/consent_record.dart';
import 'consent_list_user_messages.dart';
import 'consent_repository_failure.dart';

class ConsentTemplatePrepareSaveResult {
  final bool success;
  final String? errorMessage;
  final String? consentId;

  const ConsentTemplatePrepareSaveResult._({
    required this.success,
    this.errorMessage,
    this.consentId,
  });

  factory ConsentTemplatePrepareSaveResult.ok({String? consentId}) {
    return ConsentTemplatePrepareSaveResult._(
      success: true,
      consentId: consentId,
    );
  }

  factory ConsentTemplatePrepareSaveResult.failure(String message) {
    return ConsentTemplatePrepareSaveResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Onam şablonu hazırlama — test ve düşük seviye persist yardımcıları.
abstract final class ConsentTemplatePrepareDataSource {
  /// Tam akış: önce onam kaydı, sonra PDF (tercihen [ConsentDocumentPrepareHelper]).
  static Future<ConsentTemplatePrepareSaveResult> save({
    required ConsentRecord consent,
    required PdfOutput pdfDraft,
    required Uint8List pdfBytes,
  }) async {
    try {
      final saved = await RepositoryRegistry.consentsAsync.add(consent);
      final withFile = ConsentRecord(
        id: saved.id,
        patientId: saved.patientId,
        patientName: saved.patientName,
        createdAt: saved.createdAt,
        consentType: saved.consentType,
        status: saved.status,
        givenAt: saved.givenAt,
        expiresAt: saved.expiresAt,
        documentFileName: consent.documentFileName,
        recordedBy: saved.recordedBy,
        notes: saved.notes,
      );
      if (withFile.documentFileName != null &&
          withFile.documentFileName!.trim().isNotEmpty) {
        await RepositoryRegistry.consentsAsync.update(withFile);
      }
    } on ConsentRepositoryException catch (e) {
      return ConsentTemplatePrepareSaveResult.failure(
        ConsentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ConsentTemplatePrepareSaveResult.failure(
        ConsentListUserMessages.genericLoadFailure,
      );
    }

    try {
      await PdfOutputStorageOrchestrator.saveGeneratedPdf(
        draft: pdfDraft,
        pdfBytes: pdfBytes,
      );
    } on PdfOutputRepositoryException catch (e) {
      return ConsentTemplatePrepareSaveResult.failure(
        PdfOutputListUserMessages.forFailure(e.reason),
      );
    } on PdfOutputStorageException catch (e) {
      return ConsentTemplatePrepareSaveResult.failure(e.message);
    } catch (_) {
      return ConsentTemplatePrepareSaveResult.failure(
        PdfOutputListUserMessages.genericLoadFailure,
      );
    }

    return ConsentTemplatePrepareSaveResult.ok();
  }
}
