/// Hasta dosya metadata — DB `text` kolonları için güvenli enum parse.
enum PatientFileKind {
  patientUpload,
  generatedPdf,
  consentDocument,
  imagingReport,
  labReport,
  physiotherapyDocument,
  other;

  String get dbValue => switch (this) {
        PatientFileKind.patientUpload => 'patient_upload',
        PatientFileKind.generatedPdf => 'generated_pdf',
        PatientFileKind.consentDocument => 'consent_document',
        PatientFileKind.imagingReport => 'imaging_report',
        PatientFileKind.labReport => 'lab_report',
        PatientFileKind.physiotherapyDocument => 'physiotherapy_document',
        PatientFileKind.other => 'other',
      };

  static PatientFileKind fromDbValue(String? raw) {
    switch (raw?.trim()) {
      case 'patient_upload':
        return PatientFileKind.patientUpload;
      case 'generated_pdf':
        return PatientFileKind.generatedPdf;
      case 'consent_document':
        return PatientFileKind.consentDocument;
      case 'imaging_report':
        return PatientFileKind.imagingReport;
      case 'lab_report':
        return PatientFileKind.labReport;
      case 'physiotherapy_document':
        return PatientFileKind.physiotherapyDocument;
      default:
        return PatientFileKind.other;
    }
  }
}

enum PatientFileClinicalContext {
  patient,
  appointment,
  encounter,
  physiotherapy,
  consent,
  billing,
  other;

  String get dbValue => switch (this) {
        PatientFileClinicalContext.patient => 'patient',
        PatientFileClinicalContext.appointment => 'appointment',
        PatientFileClinicalContext.encounter => 'encounter',
        PatientFileClinicalContext.physiotherapy => 'physiotherapy',
        PatientFileClinicalContext.consent => 'consent',
        PatientFileClinicalContext.billing => 'billing',
        PatientFileClinicalContext.other => 'other',
      };

  static PatientFileClinicalContext fromDbValue(String? raw) {
    switch (raw?.trim()) {
      case 'patient':
        return PatientFileClinicalContext.patient;
      case 'appointment':
        return PatientFileClinicalContext.appointment;
      case 'encounter':
        return PatientFileClinicalContext.encounter;
      case 'physiotherapy':
        return PatientFileClinicalContext.physiotherapy;
      case 'consent':
        return PatientFileClinicalContext.consent;
      case 'billing':
        return PatientFileClinicalContext.billing;
      default:
        return PatientFileClinicalContext.other;
    }
  }
}

enum PatientFileStatus {
  active,
  archived,
  deleted,
  other;

  String get dbValue => switch (this) {
        PatientFileStatus.active => 'active',
        PatientFileStatus.archived => 'archived',
        PatientFileStatus.deleted => 'deleted',
        PatientFileStatus.other => 'other',
      };

  /// [allowPdfWorkflowAlias]: `pdf_outputs.status` taslak/hazırlandı → active.
  static PatientFileStatus fromDbValue(
    String? raw, {
    bool allowPdfWorkflowAlias = false,
  }) {
    final s = raw?.trim().toLowerCase();
    switch (s) {
      case 'active':
        return PatientFileStatus.active;
      case 'archived':
        return PatientFileStatus.archived;
      case 'deleted':
        return PatientFileStatus.deleted;
      case null:
      case '':
        return PatientFileStatus.active;
      default:
        if (allowPdfWorkflowAlias &&
            (s == 'draft' ||
                s == 'taslak' ||
                s == 'hazirlandi' ||
                s == 'hastayaverildi' ||
                s == 'gonderildi' ||
                s == 'iptal')) {
          return PatientFileStatus.active;
        }
        return PatientFileStatus.other;
    }
  }
}

enum PatientFileVisibilityScope {
  doctorAdmin,
  clinicOperations,
  physiotherapy,
  patientShareLater,
  other;

  String get dbValue => switch (this) {
        PatientFileVisibilityScope.doctorAdmin => 'doctor_admin',
        PatientFileVisibilityScope.clinicOperations => 'clinic_operations',
        PatientFileVisibilityScope.physiotherapy => 'physiotherapy',
        PatientFileVisibilityScope.patientShareLater => 'patient_share_later',
        PatientFileVisibilityScope.other => 'other',
      };

  static PatientFileVisibilityScope fromDbValue(String? raw) {
    switch (raw?.trim()) {
      case 'doctor_admin':
        return PatientFileVisibilityScope.doctorAdmin;
      case 'clinic_operations':
        return PatientFileVisibilityScope.clinicOperations;
      case 'physiotherapy':
        return PatientFileVisibilityScope.physiotherapy;
      case 'patient_share_later':
        return PatientFileVisibilityScope.patientShareLater;
      default:
        return PatientFileVisibilityScope.other;
    }
  }
}

/// Güvenli `metadata` jsonb anahtarları (allowlist).
abstract final class PatientFileMetadataExtraKeys {
  static const String templateKey = 'template_key';
  static const String templateVersion = 'template_version';
  static const String sourceModule = 'source_module';
  static const String sourceRecordId = 'source_record_id';
  static const String documentType = 'document_type';
}
