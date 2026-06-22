import '../models/lab_order.dart';
import '../models/lab_test_catalog.dart';
import 'lab_order_repository_failure.dart';

abstract final class LabOrderRemoteMapper {
  static const table = 'lab_orders';

  static const listSelectColumns =
      'id, tenant_id, patient_id, clinical_encounter_id, '
      'clinical_encounter_protocol_number, status, diagnosis, order_reason, '
      'selected_tests, selected_custom_test_ids, infection_context, '
      'infection_notes, preoperative_notes, ekg_notes, additional_notes, '
      'template_id, template_name, created_by, created_by_display, '
      'created_at, updated_at, patients(first_name, last_name)';

  static LabOrder fromRow(Map<String, dynamic> row) {
    return LabOrder(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: _embeddedPatientFullName(row['patients']) ?? 'Hasta',
      clinicalEncounterId: _optionalString(row['clinical_encounter_id']),
      clinicalEncounterProtocolNumber:
          _optionalString(row['clinical_encounter_protocol_number']),
      createdAt: _requireDateTime(row['created_at']),
      updatedAt: _optionalDateTime(row['updated_at']),
      createdBy: _optionalString(row['created_by_display']) ?? '',
      status: _enumFromDb(LabOrderStatus.values, row['status']),
      diagnosis: _optionalString(row['diagnosis']) ?? '',
      orderReason: _enumFromDb(LabOrderReason.values, row['order_reason']),
      selectedTests: _labTestsFromJson(row['selected_tests']),
      selectedCustomTestIds: _stringListFromJson(row['selected_custom_test_ids']),
      infectionContext: _enumFromDb(InfectionContext.values, row['infection_context']),
      infectionNotes: _optionalString(row['infection_notes']),
      preoperativeNotes: _optionalString(row['preoperative_notes']),
      ekgNotes: _optionalString(row['ekg_notes']),
      additionalNotes: _optionalString(row['additional_notes']),
      templateId: _optionalString(row['template_id']),
      templateName: _optionalString(row['template_name']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required LabOrder order,
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
      'diagnosis': order.diagnosis.trim(),
      'order_reason': order.orderReason.name,
      'selected_tests': order.selectedTests.map((t) => t.name).toList(),
      'selected_custom_test_ids': order.selectedCustomTestIds,
      'infection_context': order.infectionContext.name,
      if (order.infectionNotes?.trim().isNotEmpty == true)
        'infection_notes': order.infectionNotes!.trim(),
      if (order.preoperativeNotes?.trim().isNotEmpty == true)
        'preoperative_notes': order.preoperativeNotes!.trim(),
      if (order.ekgNotes?.trim().isNotEmpty == true)
        'ekg_notes': order.ekgNotes!.trim(),
      if (order.additionalNotes?.trim().isNotEmpty == true)
        'additional_notes': order.additionalNotes!.trim(),
      if (order.templateId?.trim().isNotEmpty == true)
        'template_id': order.templateId!.trim(),
      if (order.templateName?.trim().isNotEmpty == true)
        'template_name': order.templateName!.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : order.createdBy.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(LabOrder order) {
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
      'diagnosis': order.diagnosis.trim(),
      'order_reason': order.orderReason.name,
      'selected_tests': order.selectedTests.map((t) => t.name).toList(),
      'selected_custom_test_ids': order.selectedCustomTestIds,
      'infection_context': order.infectionContext.name,
      'infection_notes': order.infectionNotes?.trim().isNotEmpty == true
          ? order.infectionNotes!.trim()
          : null,
      'preoperative_notes': order.preoperativeNotes?.trim().isNotEmpty == true
          ? order.preoperativeNotes!.trim()
          : null,
      'ekg_notes':
          order.ekgNotes?.trim().isNotEmpty == true ? order.ekgNotes!.trim() : null,
      'additional_notes': order.additionalNotes?.trim().isNotEmpty == true
          ? order.additionalNotes!.trim()
          : null,
      if (order.templateId?.trim().isNotEmpty == true)
        'template_id': order.templateId!.trim()
      else
        'template_id': null,
      'template_name': order.templateName?.trim().isNotEmpty == true
          ? order.templateName!.trim()
          : null,
    };
  }

  static Map<String, dynamic> toArchiveRow({DateTime? at}) {
    final when = (at ?? DateTime.now()).toUtc();
    return {'deleted_at': when.toIso8601String()};
  }

  static List<LabTestCode> _labTestsFromJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
      );
    }
    return raw.map((item) {
      final name = item?.toString().trim();
      if (name == null || name.isEmpty) {
        throw const LabOrderRepositoryException(
          LabOrderRepositoryFailure.invalidRow,
        );
      }
      for (final value in LabTestCode.values) {
        if (value.name == name) return value;
      }
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
      );
    }).toList();
  }

  static List<String> _stringListFromJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
      );
    }
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
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
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
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
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const LabOrderRepositoryException(
      LabOrderRepositoryFailure.invalidRow,
    );
  }
}
