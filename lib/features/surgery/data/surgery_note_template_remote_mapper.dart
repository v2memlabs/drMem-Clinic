import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/surgery_note_template.dart';
abstract final class SurgeryNoteTemplateRemoteMapper {
  static const String table = 'surgery_note_templates';

  static const String listSelectColumns =
      'id, tenant_id, profile_id, name, description, payload, created_at, updated_at';

  static SurgeryNoteTemplate fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map
        ? SurgeryNoteTemplateContent.fromJson(
            Map<String, dynamic>.from(payloadRaw),
          )
        : const SurgeryNoteTemplateContent();

    return SurgeryNoteTemplate(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      profileId: PatientFileMetadataParseHelpers.requireString(map, 'profile_id'),
      name: PatientFileMetadataParseHelpers.requireString(map, 'name'),
      description:
          PatientFileMetadataParseHelpers.optionalString(map['description']) ??
              '',
      createdAt: PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
      updatedAt: PatientFileMetadataParseHelpers.optionalDateTime(map['updated_at']),
      content: payload,
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required String profileId,
    required SurgeryNoteTemplate template,
  }) {
    return {
      'tenant_id': tenantId,
      'profile_id': profileId,
      'name': template.name.trim(),
      'description': template.description.trim(),
      'payload': template.content.toJson(),
    };
  }

  static Map<String, dynamic> toUpdateRow(SurgeryNoteTemplate template) {
    return {
      'name': template.name.trim(),
      'description': template.description.trim(),
      'payload': template.content.toJson(),
    };
  }
}
