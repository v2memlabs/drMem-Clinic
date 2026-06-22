import '../models/radiology_order.dart';
import 'radiology_order_repository_failure.dart';

abstract final class RadiologyOrderRemoteMapper {
  static const table = 'radiology_orders';

  static const listSelectColumns =
      'id, tenant_id, patient_id, clinical_encounter_id, '
      'clinical_encounter_protocol_number, status, priority, diagnosis, lines, '
      'additional_notes, created_by, created_by_display, created_at, updated_at, '
      'patients(first_name, last_name)';

  static RadiologyOrder fromRow(Map<String, dynamic> row) {
    return RadiologyOrder(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: _embeddedPatientFullName(row['patients']) ?? 'Hasta',
      clinicalEncounterId: _optionalString(row['clinical_encounter_id']),
      clinicalEncounterProtocolNumber:
          _optionalString(row['clinical_encounter_protocol_number']),
      createdAt: _requireDateTime(row['created_at']),
      updatedAt: _optionalDateTime(row['updated_at']),
      createdBy: _optionalString(row['created_by_display']) ?? '',
      status: _enumFromDb(RadiologyOrderStatus.values, row['status']),
      priority: _enumFromDb(RadiologyPriority.values, row['priority']),
      diagnosis: _optionalString(row['diagnosis']) ?? '',
      lines: _linesFromJson(row['lines']),
      additionalNotes: _optionalString(row['additional_notes']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required RadiologyOrder order,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': order.patientId.trim(),
      if (order.clinicalEncounterId?.trim().isNotEmpty == true)
        'clinical_encounter_id': order.clinicalEncounterId!.trim(),
      if (order.clinicalEncounterProtocolNumber?.trim().isNotEmpty == true)
        'clinical_encounter_protocol_number':
            order.clinicalEncounterProtocolNumber!.trim(),
      'status': order.status.name,
      'priority': order.priority.name,
      'diagnosis': order.diagnosis.trim(),
      'lines': order.lines.map(_lineToJson).toList(),
      if (order.additionalNotes?.trim().isNotEmpty == true)
        'additional_notes': order.additionalNotes!.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : order.createdBy.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(RadiologyOrder order) {
    return {
      'patient_id': order.patientId.trim(),
      if (order.clinicalEncounterId?.trim().isNotEmpty == true)
        'clinical_encounter_id': order.clinicalEncounterId!.trim()
      else
        'clinical_encounter_id': null,
      if (order.clinicalEncounterProtocolNumber?.trim().isNotEmpty == true)
        'clinical_encounter_protocol_number':
            order.clinicalEncounterProtocolNumber!.trim()
      else
        'clinical_encounter_protocol_number': null,
      'status': order.status.name,
      'priority': order.priority.name,
      'diagnosis': order.diagnosis.trim(),
      'lines': order.lines.map(_lineToJson).toList(),
      'additional_notes': order.additionalNotes?.trim().isNotEmpty == true
          ? order.additionalNotes!.trim()
          : null,
    };
  }

  static Map<String, dynamic> toSoftDeleteRow({DateTime? at}) {
    final when = (at ?? DateTime.now()).toUtc();
    return {'deleted_at': when.toIso8601String()};
  }

  static Map<String, dynamic> _lineToJson(RadiologyOrderLine line) {
    return {
      'modality': line.modality.name,
      'bodyRegion': line.bodyRegion,
      'side': line.side.name,
      'clinicalIndication': line.clinicalIndication,
      'withContrast': line.withContrast,
      if (line.notes != null && line.notes!.trim().isNotEmpty)
        'notes': line.notes!.trim(),
    };
  }

  static List<RadiologyOrderLine> _linesFromJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.invalidRow,
      );
    }
    return raw.map((item) {
      if (item is! Map) {
        throw const RadiologyOrderRepositoryException(
          RadiologyOrderRepositoryFailure.invalidRow,
        );
      }
      return RadiologyOrderLine(
        modality: _enumFromDb(RadiologyModality.values, item['modality']),
        bodyRegion: _optionalString(item['bodyRegion']) ?? '',
        side: _enumFromDb(RadiologySide.values, item['side']),
        clinicalIndication: _optionalString(item['clinicalIndication']) ?? '',
        withContrast: item['withContrast'] == true,
        notes: _optionalString(item['notes']),
      );
    }).toList();
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.invalidRow,
      );
    }
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static DateTime _requireDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static DateTime? _optionalDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
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
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const RadiologyOrderRepositoryException(
      RadiologyOrderRepositoryFailure.invalidRow,
    );
  }
}
