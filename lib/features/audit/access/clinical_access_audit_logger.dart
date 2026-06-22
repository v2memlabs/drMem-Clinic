import 'dart:async';

import 'audit_access_event.dart';
import 'audit_access_event_provider.dart';
import 'audit_access_event_type.dart';
import 'audit_access_failure_category.dart';
import 'audit_access_metadata_sanitizer.dart';
import '../../clinical_encounter/data/assistant_clinical_summary_repository_failure.dart';
import '../../clinical_encounter/data/physiotherapist_clinical_summary_repository_failure.dart';
import '../../clinical_encounter/data/clinical_encounter_repository_failure.dart';

/// Klinik ve güvenli özet erişim audit kayıtları (hassas içerik yok).
abstract final class ClinicalAccessAuditLogger {
  static void clinicalFullList({
    String? patientId,
    int? resultCount,
    bool success = true,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalFullList,
        success: success,
        failureCategory: failureCategory,
        source: source,
        patientId: patientId,
        metadata: AuditAccessMetadataSanitizer.buildBase(
          success: success,
          failureCategory: failureCategory,
          source: source,
          resultCount: resultCount,
          filteredByPatient:
              patientId != null && patientId.trim().isNotEmpty,
        ),
      ),
    );
  }

  static void clinicalFullView({
    required String encounterId,
    String? patientId,
    bool success = true,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalFullView,
        success: success,
        failureCategory: failureCategory,
        source: source,
        patientId: patientId,
        encounterId: encounterId,
        metadata: AuditAccessMetadataSanitizer.buildBase(
          success: success,
          failureCategory: failureCategory,
          source: source,
        ),
      ),
    );
  }

  static void clinicalInternalNoteView({
    required String encounterId,
    String? patientId,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalInternalNoteView,
        source: source,
        patientId: patientId,
        encounterId: encounterId,
        metadata: AuditAccessMetadataSanitizer.sanitize({
          'includes_internal_note_access': true,
          'source': source,
        }),
      ),
    );
  }

  static void assistantSummaryList({
    String? patientId,
    int? resultCount,
    bool success = true,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalSummaryAssistantList,
        success: success,
        failureCategory: failureCategory,
        source: source,
        patientId: patientId,
        metadata: AuditAccessMetadataSanitizer.buildBase(
          success: success,
          failureCategory: failureCategory,
          source: source,
          resultCount: resultCount,
          filteredByPatient:
              patientId != null && patientId.trim().isNotEmpty,
        ),
      ),
    );
  }

  static void assistantSummaryView({
    required String encounterId,
    String? patientId,
    bool success = true,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalSummaryAssistantView,
        success: success,
        failureCategory: failureCategory,
        source: source,
        patientId: patientId,
        encounterId: encounterId,
        metadata: AuditAccessMetadataSanitizer.buildBase(
          success: success,
          failureCategory: failureCategory,
          source: source,
        ),
      ),
    );
  }

  static void physiotherapistSummaryList({
    String? patientId,
    int? resultCount,
    bool success = true,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalSummaryPhysiotherapistList,
        success: success,
        failureCategory: failureCategory,
        source: source,
        patientId: patientId,
        metadata: AuditAccessMetadataSanitizer.buildBase(
          success: success,
          failureCategory: failureCategory,
          source: source,
          resultCount: resultCount,
          filteredByPatient:
              patientId != null && patientId.trim().isNotEmpty,
        ),
      ),
    );
  }

  static void physiotherapistSummaryView({
    required String encounterId,
    String? patientId,
    bool success = true,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.clinicalSummaryPhysiotherapistView,
        success: success,
        failureCategory: failureCategory,
        source: source,
        patientId: patientId,
        encounterId: encounterId,
        metadata: AuditAccessMetadataSanitizer.buildBase(
          success: success,
          failureCategory: failureCategory,
          source: source,
        ),
      ),
    );
  }

  static void permissionDenied({
    required String attemptedEventType,
    String? failureCategory,
    String source = 'data_source',
  }) {
    _record(
      AuditAccessEvent(
        eventType: AuditAccessEventType.permissionDenied,
        success: false,
        failureCategory:
            failureCategory ?? AuditAccessFailureCategory.forbidden,
        source: source,
        metadata: AuditAccessMetadataSanitizer.sanitize({
          'attempted_event_type': attemptedEventType,
          'source': source,
        }),
      ),
    );
  }

  static String? categoryForClinicalFailure(
    ClinicalEncounterRepositoryFailure reason,
  ) {
    switch (reason) {
      case ClinicalEncounterRepositoryFailure.forbidden:
        return AuditAccessFailureCategory.forbidden;
      case ClinicalEncounterRepositoryFailure.noActiveTenant:
        return AuditAccessFailureCategory.noActiveTenant;
      case ClinicalEncounterRepositoryFailure.notFound:
        return AuditAccessFailureCategory.notFound;
      case ClinicalEncounterRepositoryFailure.network:
        return AuditAccessFailureCategory.network;
      case ClinicalEncounterRepositoryFailure.notConfigured:
        return AuditAccessFailureCategory.notConfigured;
      case ClinicalEncounterRepositoryFailure.invalidClinicalData:
        return AuditAccessFailureCategory.invalidData;
      default:
        return AuditAccessFailureCategory.unknown;
    }
  }

  static String? categoryForAssistantSummaryFailure(
    AssistantClinicalSummaryRepositoryFailure reason,
  ) {
    switch (reason) {
      case AssistantClinicalSummaryRepositoryFailure.forbidden:
        return AuditAccessFailureCategory.forbidden;
      case AssistantClinicalSummaryRepositoryFailure.noActiveTenant:
        return AuditAccessFailureCategory.noActiveTenant;
      case AssistantClinicalSummaryRepositoryFailure.network:
        return AuditAccessFailureCategory.network;
      case AssistantClinicalSummaryRepositoryFailure.notConfigured:
        return AuditAccessFailureCategory.notConfigured;
      default:
        return AuditAccessFailureCategory.unknown;
    }
  }

  static String? categoryForPhysiotherapistSummaryFailure(
    PhysiotherapistClinicalSummaryRepositoryFailure reason,
  ) {
    switch (reason) {
      case PhysiotherapistClinicalSummaryRepositoryFailure.forbidden:
        return AuditAccessFailureCategory.forbidden;
      case PhysiotherapistClinicalSummaryRepositoryFailure.noActiveTenant:
        return AuditAccessFailureCategory.noActiveTenant;
      case PhysiotherapistClinicalSummaryRepositoryFailure.network:
        return AuditAccessFailureCategory.network;
      case PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured:
        return AuditAccessFailureCategory.notConfigured;
      default:
        return AuditAccessFailureCategory.unknown;
    }
  }

  static void _record(AuditAccessEvent event) {
    unawaited(
      AuditAccessEventProvider.recorder.record(event).catchError((_) {}),
    );
  }
}
