import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../../patient_files/data/patient_file_metadata_sanitizer.dart';
import '../../patient_files/data/patient_file_storage_path_builder.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../models/pdf_output.dart';

/// `pdf_outputs` insert / select — içerik/URL UI'da yok.
abstract final class PdfOutputRemoteMapper {
  static const String table = 'pdf_outputs';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, created_by, document_type, source_module, '
      'source_record_id, storage_bucket, storage_path, display_name, status, '
      'metadata, created_at, updated_at, deleted_at, '
      'patients(first_name, last_name)';

  static PdfOutput fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final meta = Map<String, Object?>.from(
      PatientFileMetadataSanitizer.sanitize(
        PatientFileMetadataParseHelpers.coerceMetadataMap(map['metadata']),
      ),
    );

    final patientName = _embeddedPatientFullName(map['patients']) ??
        PatientFileMetadataParseHelpers.optionalString(
          meta['created_by_display'],
        ) ??
        'Hasta';

    final createdAt = _parseDateTime(map['created_at']) ?? DateTime.now().toUtc();
    final documentType = _documentTypeFromDb(
      PatientFileMetadataParseHelpers.optionalString(map['document_type']),
    );
    final title = PatientFileMetadataParseHelpers.optionalString(
          map['display_name'],
        ) ??
        documentTypeLabel(documentType);

    return PdfOutput(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      patientId: PatientFileMetadataParseHelpers.requireString(map, 'patient_id'),
      patientName: patientName,
      createdAt: createdAt,
      documentType: documentType,
      title: title,
      relatedDiagnosis: PatientFileMetadataParseHelpers.optionalString(
        meta['related_diagnosis'],
      ),
      relatedTreatmentPlan: PatientFileMetadataParseHelpers.optionalString(
        meta['related_treatment_plan'],
      ),
      contentSummary:
          PatientFileMetadataParseHelpers.optionalString(meta['content_summary']) ??
              '',
      warningNote:
          PatientFileMetadataParseHelpers.optionalString(meta['warning_note']) ??
              '',
      createdBy:
          PatientFileMetadataParseHelpers.optionalString(meta['created_by_display']) ??
              'Doktor',
      status: _statusFromDb(
        PatientFileMetadataParseHelpers.optionalString(map['status']),
      ),
      sourceModule: PatientFileMetadataParseHelpers.optionalString(
        map['source_module'],
      ),
      sourceRecordId: PatientFileMetadataParseHelpers.optionalString(
        map['source_record_id'],
      ),
      storageBucket: PatientFileMetadataParseHelpers.optionalString(
        map['storage_bucket'],
      ),
      storagePath: PatientFileMetadataParseHelpers.optionalString(
        map['storage_path'],
      ),
    );
  }

  static String? _embeddedPatientFullName(dynamic value) {
    final embed = _parsePatientEmbed(value);
    if (embed == null) return null;
    final full = '${embed.$1} ${embed.$2}'.trim();
    return full.isEmpty ? null : full;
  }

  static (String, String)? _parsePatientEmbed(dynamic value) {
    if (value == null) return null;
    Map<String, dynamic>? map;
    if (value is Map<String, dynamic>) {
      map = value;
    } else if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) map = first;
    }
    if (map == null) return null;
    final fn = (map['first_name'] as String?)?.trim() ?? '';
    final ln = (map['last_name'] as String?)?.trim() ?? '';
    if (fn.isEmpty && ln.isEmpty) return null;
    return (fn, ln);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toUtc();
    } catch (_) {
      return null;
    }
  }

  static DocumentType _documentTypeFromDb(String? raw) {
    return switch (raw?.trim()) {
      'muayene_ozeti' => DocumentType.muayeneOzeti,
      'goruntuleme_ozeti' => DocumentType.goruntulemeOzeti,
      'tedavi_plani' => DocumentType.tedaviPlani,
      'egzersiz_programi' => DocumentType.egzersizProgrami,
      'post_op_protokol' => DocumentType.postOpProtokol,
      'ameliyat_girisim_notu' => DocumentType.ameliyatGirisimNotu,
      'ameliyat_sonrasi' => DocumentType.ameliyatSonrasi,
      'enjeksiyon_sonrasi' => DocumentType.enjeksiyonSonrasi,
      'fizyoterapi_yonlendirme' => DocumentType.fizyoterapiYonlendirme,
      'kontrol_plani' => DocumentType.kontrolPlani,
      'hasta_bilgilendirme_formu' => DocumentType.hastaBilgilendirmeFormu,
      'onam_formu' => DocumentType.onamFormu,
      _ => DocumentType.muayeneOzeti,
    };
  }

  static PdfStatus _statusFromDb(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'draft' => PdfStatus.taslak,
      'hazirlandi' => PdfStatus.hazirlandi,
      'hastayaverildi' => PdfStatus.hastayaVerildi,
      'gonderildi' => PdfStatus.gonderildi,
      'iptal' => PdfStatus.iptal,
      _ => PdfStatus.hazirlandi,
    };
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required String patientId,
    required String pdfOutputId,
    required String storagePath,
    required PdfOutput output,
    required int fileSizeBytes,
    String? createdByProfileId,
  }) {
    final title = output.title.trim().isEmpty ? 'Yeni PDF' : output.title.trim();
    final meta = PatientFileMetadataSanitizer.sanitize({
      if (output.relatedDiagnosis != null &&
          output.relatedDiagnosis!.trim().isNotEmpty)
        'related_diagnosis': output.relatedDiagnosis!.trim(),
      if (output.relatedTreatmentPlan != null &&
          output.relatedTreatmentPlan!.trim().isNotEmpty)
        'related_treatment_plan': output.relatedTreatmentPlan!.trim(),
      if (output.contentSummary.trim().isNotEmpty)
        'content_summary': output.contentSummary.trim().length > 500
            ? output.contentSummary.trim().substring(0, 500)
            : output.contentSummary.trim(),
      if (output.warningNote.trim().isNotEmpty)
        'warning_note': output.warningNote.trim().length > 500
            ? output.warningNote.trim().substring(0, 500)
            : output.warningNote.trim(),
      if (output.sourceModule != null) 'source_module': output.sourceModule,
      if (output.sourceRecordId != null) 'source_record_id': output.sourceRecordId,
      'created_by_display': output.createdBy,
    });

    return {
      'id': pdfOutputId,
      'tenant_id': tenantId,
      'patient_id': patientId,
      if (createdByProfileId != null && createdByProfileId.trim().isNotEmpty)
        'created_by': createdByProfileId.trim(),
      'document_type': _documentTypeDb(output.documentType),
      'source_module': output.sourceModule,
      'source_record_id': output.sourceRecordId,
      'storage_path': storagePath,
      'storage_bucket': PatientFileStoragePathBuilder.defaultBucket,
      'file_kind': 'generated_pdf',
      'clinical_context': _clinicalContext(output.sourceModule),
      if (output.sourceModule == pdfSourceModuleClinicalEncounter &&
          output.sourceRecordId != null)
        'encounter_id': output.sourceRecordId,
      'display_name': title,
      'original_file_name': '$title.pdf',
      'mime_type': 'application/pdf',
      'file_size_bytes': fileSizeBytes,
      'status': _statusDb(output.status),
      'visibility_scope': _visibilityScopeForCurrentRole(),
      'metadata': meta,
    };
  }

  static String _visibilityScopeForCurrentRole() {
    return AuthSession.currentUser?.role == AppRoles.assistant
        ? 'clinic_operations'
        : 'doctor_admin';
  }

  static String _documentTypeDb(DocumentType type) {
    return switch (type) {
      DocumentType.muayeneOzeti => 'muayene_ozeti',
      DocumentType.goruntulemeOzeti => 'goruntuleme_ozeti',
      DocumentType.tedaviPlani => 'tedavi_plani',
      DocumentType.egzersizProgrami => 'egzersiz_programi',
      DocumentType.postOpProtokol => 'post_op_protokol',
      DocumentType.ameliyatGirisimNotu => 'ameliyat_girisim_notu',
      DocumentType.ameliyatSonrasi => 'ameliyat_sonrasi',
      DocumentType.enjeksiyonSonrasi => 'enjeksiyon_sonrasi',
      DocumentType.fizyoterapiYonlendirme => 'fizyoterapi_yonlendirme',
      DocumentType.kontrolPlani => 'kontrol_plani',
      DocumentType.hastaBilgilendirmeFormu => 'hasta_bilgilendirme_formu',
      DocumentType.onamFormu => 'onam_formu',
    };
  }

  static String _statusDb(PdfStatus status) {
    return switch (status) {
      PdfStatus.taslak => 'draft',
      PdfStatus.hazirlandi => 'hazirlandi',
      PdfStatus.hastayaVerildi => 'hastayaverildi',
      PdfStatus.gonderildi => 'gonderildi',
      PdfStatus.iptal => 'iptal',
    };
  }

  static String _clinicalContext(String? sourceModule) {
    return switch (sourceModule) {
      pdfSourceModuleClinicalEncounter => 'encounter',
      pdfSourceModuleConsentTemplate => 'consent',
      pdfSourceModulePhysiotherapyReferral => 'physiotherapy',
      _ => 'patient',
    };
  }
}
