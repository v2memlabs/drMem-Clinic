import '../models/clinical_report.dart';
import 'clinical_report_repository_failure.dart';

abstract final class ClinicalReportRemoteMapper {
  static const table = 'clinical_reports';

  static const listSelectColumns =
      'id, tenant_id, patient_id, clinical_encounter_id, '
      'clinical_encounter_protocol_number, report_number, document_date_source, '
      'status, report_type, diagnosis, body_text, type_payload, '
      'created_by, created_by_display, created_at, updated_at, '
      'patients(first_name, last_name)';

  static ClinicalReport fromRow(Map<String, dynamic> row) {
    final payload = _payloadMap(row['type_payload']);

    return ClinicalReport(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: _embeddedPatientFullName(row['patients']) ?? 'Hasta',
      clinicalEncounterId: _optionalString(row['clinical_encounter_id']),
      clinicalEncounterProtocolNumber:
          _optionalString(row['clinical_encounter_protocol_number']),
      reportNumber: _optionalString(row['report_number']),
      documentDateSource: _enumFromDb(
        ClinicalReportDocumentDateSource.values,
        row['document_date_source'],
      ),
      createdAt: _requireDateTime(row['created_at']),
      updatedAt: _optionalDateTime(row['updated_at']),
      createdBy: _optionalString(row['created_by_display']) ?? '',
      status: _enumFromDb(ClinicalReportStatus.values, row['status']),
      reportType: _enumFromDb(ClinicalReportType.values, row['report_type']),
      diagnosis: _optionalString(row['diagnosis']) ?? '',
      bodyText: _optionalString(row['body_text']) ?? '',
      startDate: _optionalDate(payload['startDate']),
      endDate: _optionalDate(payload['endDate']),
      restDays: _optionalInt(payload['restDays']),
      treatmentApproach: _optionalEnum(
        ClinicalReportTreatmentApproach.values,
        payload['treatmentApproach'],
      ),
      restrictionNotes: _optionalString(payload['restrictionNotes']),
      statusDuration: _optionalString(payload['statusDuration']),
      statusRecommendation: _optionalString(payload['statusRecommendation']),
      statusSuitability: _optionalEnum(
        ClinicalReportStatusSuitability.values,
        payload['statusSuitability'],
      ),
      supplementaryNotes: _optionalString(payload['supplementaryNotes']),
      flightDecision: _optionalEnum(
        ClinicalReportFlightDecision.values,
        payload['flightDecision'],
      ),
      deviceUsageDuration: _optionalString(payload['deviceUsageDuration']),
      weightBearing: _optionalEnum(
        ClinicalReportWeightBearing.values,
        payload['weightBearing'],
      ),
      deviceName: _optionalString(payload['deviceName']),
      deviceUsageNotes: _optionalString(payload['deviceUsageNotes']),
      flightNotes: _optionalString(payload['flightNotes']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required ClinicalReport report,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': report.patientId.trim(),
      if (report.clinicalEncounterId?.trim().isNotEmpty == true)
        'clinical_encounter_id': report.clinicalEncounterId!.trim(),
      if (report.clinicalEncounterProtocolNumber?.trim().isNotEmpty == true)
        'clinical_encounter_protocol_number':
            report.clinicalEncounterProtocolNumber!.trim(),
      if (report.reportNumber?.trim().isNotEmpty == true)
        'report_number': report.reportNumber!.trim(),
      'document_date_source': report.documentDateSource.name,
      'status': report.status.name,
      'report_type': report.reportType.name,
      'diagnosis': report.diagnosis.trim(),
      'body_text': report.bodyText.trim(),
      'type_payload': toTypePayload(report),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : report.createdBy.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(ClinicalReport report) {
    return {
      'patient_id': report.patientId.trim(),
      if (report.clinicalEncounterId?.trim().isNotEmpty == true)
        'clinical_encounter_id': report.clinicalEncounterId!.trim()
      else
        'clinical_encounter_id': null,
      if (report.clinicalEncounterProtocolNumber?.trim().isNotEmpty == true)
        'clinical_encounter_protocol_number':
            report.clinicalEncounterProtocolNumber!.trim()
      else
        'clinical_encounter_protocol_number': null,
      if (report.reportNumber?.trim().isNotEmpty == true)
        'report_number': report.reportNumber!.trim()
      else
        'report_number': null,
      'document_date_source': report.documentDateSource.name,
      'status': report.status.name,
      'report_type': report.reportType.name,
      'diagnosis': report.diagnosis.trim(),
      'body_text': report.bodyText.trim(),
      'type_payload': toTypePayload(report),
    };
  }

  static Map<String, dynamic> toTypePayload(ClinicalReport report) {
    final payload = <String, dynamic>{};

    void putString(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        payload[key] = value.trim();
      }
    }

    void putEnum(String key, Enum? value) {
      if (value != null) payload[key] = value.name;
    }

    if (report.startDate != null) {
      payload['startDate'] = _dateOnly(report.startDate!);
    }
    if (report.endDate != null) {
      payload['endDate'] = _dateOnly(report.endDate!);
    }
    if (report.restDays != null) payload['restDays'] = report.restDays;

    putEnum('treatmentApproach', report.treatmentApproach);
    putString('restrictionNotes', report.restrictionNotes);
    putString('statusDuration', report.statusDuration);
    putString('statusRecommendation', report.statusRecommendation);
    putEnum('statusSuitability', report.statusSuitability);
    putString('supplementaryNotes', report.supplementaryNotes);
    putEnum('flightDecision', report.flightDecision);
    putString('deviceUsageDuration', report.deviceUsageDuration);
    putEnum('weightBearing', report.weightBearing);
    putString('deviceName', report.deviceName);
    putString('deviceUsageNotes', report.deviceUsageNotes);
    putString('flightNotes', report.flightNotes);

    return payload;
  }

  static Map<String, dynamic> _payloadMap(Object? raw) {
    if (raw == null) return const {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const ClinicalReportRepositoryException(
      ClinicalReportRepositoryFailure.invalidRow,
    );
  }

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.invalidRow,
      );
    }
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static int? _optionalInt(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  static DateTime _requireDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static DateTime? _optionalDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  static DateTime? _optionalDate(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
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

  static T _enumFromDb<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const ClinicalReportRepositoryException(
      ClinicalReportRepositoryFailure.invalidRow,
    );
  }

  static T? _optionalEnum<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
