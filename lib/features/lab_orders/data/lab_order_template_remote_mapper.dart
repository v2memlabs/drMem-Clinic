import '../models/lab_order.dart';
import '../models/lab_order_template.dart';
import '../models/lab_test_catalog.dart';
import 'lab_order_template_repository_failure.dart';

abstract final class LabOrderTemplateRemoteMapper {
  static const table = 'lab_order_templates';

  static const listSelectColumns =
      'id, tenant_id, name, description, selected_tests, '
      'selected_custom_test_ids, default_order_reason, default_diagnosis, '
      'default_infection_context, preoperative_notes, ekg_notes, '
      'additional_notes, created_by, created_by_display, created_at, updated_at';

  static LabOrderTemplate fromRow(Map<String, dynamic> row) {
    return LabOrderTemplate(
      id: _requireString(row, 'id'),
      name: _requireString(row, 'name'),
      description: _optionalString(row['description']),
      createdBy: _optionalString(row['created_by_display']) ?? '',
      createdAt: _requireDateTime(row['created_at']),
      updatedAt: _optionalDateTime(row['updated_at']),
      selectedTests: _labTestsFromJson(row['selected_tests']),
      selectedCustomTestIds: _stringListFromJson(row['selected_custom_test_ids']),
      defaultOrderReason:
          _enumFromDb(LabOrderReason.values, row['default_order_reason']),
      defaultDiagnosis: _optionalString(row['default_diagnosis']),
      defaultInfectionContext: _enumFromDb(
        InfectionContext.values,
        row['default_infection_context'],
      ),
      preoperativeNotes: _optionalString(row['preoperative_notes']),
      ekgNotes: _optionalString(row['ekg_notes']),
      additionalNotes: _optionalString(row['additional_notes']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required LabOrderTemplate template,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'name': template.name.trim(),
      if (template.description?.trim().isNotEmpty == true)
        'description': template.description!.trim(),
      'selected_tests': template.selectedTests.map((t) => t.name).toList(),
      'selected_custom_test_ids': template.selectedCustomTestIds,
      'default_order_reason': template.defaultOrderReason.name,
      if (template.defaultDiagnosis?.trim().isNotEmpty == true)
        'default_diagnosis': template.defaultDiagnosis!.trim(),
      'default_infection_context': template.defaultInfectionContext.name,
      if (template.preoperativeNotes?.trim().isNotEmpty == true)
        'preoperative_notes': template.preoperativeNotes!.trim(),
      if (template.ekgNotes?.trim().isNotEmpty == true)
        'ekg_notes': template.ekgNotes!.trim(),
      if (template.additionalNotes?.trim().isNotEmpty == true)
        'additional_notes': template.additionalNotes!.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : template.createdBy.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(LabOrderTemplate template) {
    return {
      'name': template.name.trim(),
      'description': template.description?.trim().isNotEmpty == true
          ? template.description!.trim()
          : null,
      'selected_tests': template.selectedTests.map((t) => t.name).toList(),
      'selected_custom_test_ids': template.selectedCustomTestIds,
      'default_order_reason': template.defaultOrderReason.name,
      'default_diagnosis': template.defaultDiagnosis?.trim().isNotEmpty == true
          ? template.defaultDiagnosis!.trim()
          : null,
      'default_infection_context': template.defaultInfectionContext.name,
      'preoperative_notes': template.preoperativeNotes?.trim().isNotEmpty == true
          ? template.preoperativeNotes!.trim()
          : null,
      'ekg_notes':
          template.ekgNotes?.trim().isNotEmpty == true ? template.ekgNotes!.trim() : null,
      'additional_notes': template.additionalNotes?.trim().isNotEmpty == true
          ? template.additionalNotes!.trim()
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
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
      );
    }
    return raw.map((item) {
      final name = item?.toString().trim();
      if (name == null || name.isEmpty) {
        throw const LabOrderTemplateRepositoryException(
          LabOrderTemplateRepositoryFailure.invalidRow,
        );
      }
      for (final value in LabTestCode.values) {
        if (value.name == name) return value;
      }
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
      );
    }).toList();
  }

  static List<String> _stringListFromJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
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
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
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
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static DateTime? _optionalDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  static T _enumFromDb<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const LabOrderTemplateRepositoryException(
      LabOrderTemplateRepositoryFailure.invalidRow,
    );
  }
}
