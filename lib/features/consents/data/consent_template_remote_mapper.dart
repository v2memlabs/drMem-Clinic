import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/consent_record.dart';
import '../models/consent_template.dart';
import 'consent_repository_failure.dart';

abstract final class ConsentTemplateRemoteMapper {
  static const String table = 'consent_templates';

  static const String listSelectColumns =
      'id, tenant_id, title, category, consent_type, description, version, '
      'content_body, document_file_name, required_for, is_active, notes, '
      'created_at, updated_at';

  static ConsentTemplate fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final category =
        PatientFileMetadataParseHelpers.optionalString(map['category']) ??
            ConsentTemplateCategories.acikRiza;

    return ConsentTemplate(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      title: PatientFileMetadataParseHelpers.requireString(map, 'title'),
      category: category,
      description:
          PatientFileMetadataParseHelpers.optionalString(map['description']) ??
              '',
      version:
          PatientFileMetadataParseHelpers.optionalString(map['version']) ??
              '1.0',
      isActive: map['is_active'] == true,
      createdAt:
          PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
      updatedAt:
          PatientFileMetadataParseHelpers.requireDateTime(map['updated_at']),
      documentFileName:
          PatientFileMetadataParseHelpers.optionalString(
                map['document_file_name'],
              ) ??
              '',
      contentPreview:
          PatientFileMetadataParseHelpers.optionalString(map['content_body']) ??
              '',
      requiredFor:
          PatientFileMetadataParseHelpers.optionalString(map['required_for']) ??
              ConsentTemplateRequiredFor.gerekliDegil,
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required ConsentTemplate template,
    String? ownerProfileId,
  }) {
    return {
      'tenant_id': tenantId,
      if (ownerProfileId != null) 'owner_profile_id': ownerProfileId,
      'title': template.title.trim(),
      'category': template.category.trim(),
      'consent_type': consentTypeFromTemplateCategory(template.category).name,
      'description': template.description.trim(),
      'version': template.version.trim().isEmpty ? '1.0' : template.version.trim(),
      'content_source': 'text',
      'content_body': template.contentPreview.trim(),
      'document_file_name': template.documentFileName.trim().isEmpty
          ? null
          : template.documentFileName.trim(),
      'required_for': template.requiredFor.trim(),
      'is_active': template.isActive,
      'notes': template.notes?.trim().isEmpty ?? true
          ? null
          : template.notes!.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(ConsentTemplate template) {
    return {
      'title': template.title.trim(),
      'category': template.category.trim(),
      'consent_type': consentTypeFromTemplateCategory(template.category).name,
      'description': template.description.trim(),
      'version': template.version.trim().isEmpty ? '1.0' : template.version.trim(),
      'content_body': template.contentPreview.trim(),
      'document_file_name': template.documentFileName.trim().isEmpty
          ? null
          : template.documentFileName.trim(),
      'required_for': template.requiredFor.trim(),
      'is_active': template.isActive,
      'notes': template.notes?.trim().isEmpty ?? true
          ? null
          : template.notes!.trim(),
    };
  }
}
