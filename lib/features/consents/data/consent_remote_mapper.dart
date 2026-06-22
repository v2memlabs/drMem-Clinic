import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/consent_record.dart';
import '../models/consent_signature_mode.dart';
import 'consent_repository_failure.dart';

/// `consents` tablosu ↔ [ConsentRecord] map.
abstract final class ConsentRemoteMapper {
  static const String table = 'consents';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, consent_type, status, given_at, expires_at, '
      'document_file_name, notes, recorded_by_display, created_at, '
      'template_id, template_version, pdf_output_id, appointment_id, encounter_id, '
      'signature_mode, metadata, '
      'patients(first_name, last_name, file_number)';

  static ConsentRecord fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final patientName = _embeddedPatientFullName(map['patients']) ?? 'Hasta';

    return ConsentRecord(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      patientId: PatientFileMetadataParseHelpers.requireString(map, 'patient_id'),
      patientName: patientName,
      createdAt: PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
      consentType: _enumFromDb(
        ConsentType.values,
        map['consent_type'],
        ConsentRepositoryFailure.invalidRow,
      ),
      status: _enumFromDb(
        ConsentStatus.values,
        map['status'],
        ConsentRepositoryFailure.invalidRow,
      ),
      givenAt: PatientFileMetadataParseHelpers.optionalDateTime(map['given_at']),
      expiresAt:
          PatientFileMetadataParseHelpers.optionalDateTime(map['expires_at']),
      documentFileName:
          PatientFileMetadataParseHelpers.optionalString(map['document_file_name']),
      recordedBy: PatientFileMetadataParseHelpers.optionalString(
            map['recorded_by_display'],
          ) ??
          '—',
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes']),
      templateId: PatientFileMetadataParseHelpers.optionalString(map['template_id']),
      templateVersion:
          PatientFileMetadataParseHelpers.optionalString(map['template_version']),
      pdfOutputId:
          PatientFileMetadataParseHelpers.optionalString(map['pdf_output_id']),
      appointmentId:
          PatientFileMetadataParseHelpers.optionalString(map['appointment_id']),
      encounterId:
          PatientFileMetadataParseHelpers.optionalString(map['encounter_id']),
      signatureMode: consentSignatureModeFromDb(
        PatientFileMetadataParseHelpers.optionalString(map['signature_mode']),
      ),
      metadata: _metadataFromDb(map['metadata']),
    );
  }

  static Map<String, Object?> _metadataFromDb(Object? raw) {
    if (raw is Map) {
      return Map<String, Object?>.from(raw);
    }
    return const {};
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required ConsentRecord consent,
    String? createdByProfileId,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': consent.patientId.trim(),
      'consent_type': consent.consentType.name,
      'status': consent.status.name,
      'given_at': consent.givenAt?.toUtc().toIso8601String(),
      'expires_at': consent.expiresAt?.toUtc().toIso8601String(),
      'document_file_name': consent.documentFileName?.trim().isEmpty ?? true
          ? null
          : consent.documentFileName!.trim(),
      'notes': consent.notes?.trim().isEmpty ?? true ? null : consent.notes!.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'recorded_by_display': consent.recordedBy.trim().isEmpty
          ? null
          : consent.recordedBy.trim(),
      if (consent.templateId != null && consent.templateId!.trim().isNotEmpty)
        'template_id': consent.templateId!.trim(),
      if (consent.templateVersion != null &&
          consent.templateVersion!.trim().isNotEmpty)
        'template_version': consent.templateVersion!.trim(),
      if (consent.pdfOutputId != null && consent.pdfOutputId!.trim().isNotEmpty)
        'pdf_output_id': consent.pdfOutputId!.trim(),
      if (consent.appointmentId != null && consent.appointmentId!.trim().isNotEmpty)
        'appointment_id': consent.appointmentId!.trim(),
      if (consent.encounterId != null && consent.encounterId!.trim().isNotEmpty)
        'encounter_id': consent.encounterId!.trim(),
      'signature_mode': consentSignatureModeToDb(consent.signatureMode),
      'metadata': consent.metadata,
    };
  }

  static Map<String, dynamic> toUpdateRow(ConsentRecord consent) {
    return {
      'consent_type': consent.consentType.name,
      'status': consent.status.name,
      'given_at': consent.givenAt?.toUtc().toIso8601String(),
      'expires_at': consent.expiresAt?.toUtc().toIso8601String(),
      'document_file_name': consent.documentFileName?.trim().isEmpty ?? true
          ? null
          : consent.documentFileName!.trim(),
      'notes': consent.notes?.trim().isEmpty ?? true ? null : consent.notes!.trim(),
      'recorded_by_display': consent.recordedBy.trim().isEmpty
          ? null
          : consent.recordedBy.trim(),
      if (consent.templateId != null && consent.templateId!.trim().isNotEmpty)
        'template_id': consent.templateId!.trim(),
      if (consent.templateVersion != null &&
          consent.templateVersion!.trim().isNotEmpty)
        'template_version': consent.templateVersion!.trim(),
      if (consent.pdfOutputId != null && consent.pdfOutputId!.trim().isNotEmpty)
        'pdf_output_id': consent.pdfOutputId!.trim(),
      if (consent.appointmentId != null && consent.appointmentId!.trim().isNotEmpty)
        'appointment_id': consent.appointmentId!.trim(),
      if (consent.encounterId != null && consent.encounterId!.trim().isNotEmpty)
        'encounter_id': consent.encounterId!.trim(),
      'signature_mode': consentSignatureModeToDb(consent.signatureMode),
      'metadata': consent.metadata,
    };
  }

  static String? _embeddedPatientFullName(dynamic value) {
    if (value is Map) {
      final first = value['first_name']?.toString().trim() ?? '';
      final last = value['last_name']?.toString().trim() ?? '';
      final name = '$first $last'.trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  static T _enumFromDb<T extends Enum>(
    List<T> values,
    Object? raw,
    ConsentRepositoryFailure failure,
  ) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw ConsentRepositoryException(failure);
    }
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw ConsentRepositoryException(failure);
  }
}
