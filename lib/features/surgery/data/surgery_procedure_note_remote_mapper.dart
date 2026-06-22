import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/surgery_procedure_note.dart';
import 'surgery_procedure_note_repository_failure.dart';

abstract final class SurgeryProcedureNoteRemoteMapper {
  static const String table = 'surgery_procedure_notes';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, procedure_date, procedure_type, body_region, '
      'side, diagnosis, procedure_name, anesthesia_type, asa_score, '
      'tourniquet_used, procedure_details, complications, implant_or_material_info, '
      'arthroscopy_findings, post_op_recommendations, '
      'physiotherapy_start_recommendation, control_schedule, surgeon_name, '
      'assistant_info, notes, created_by, created_at, '
      'patients(first_name, last_name)';

  static SurgeryProcedureNote fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final patientName = _embeddedPatientFullName(map['patients']) ?? 'Hasta';
    final procedureDate = PatientFileMetadataParseHelpers.requireDateTime(
      map['procedure_date'],
    );

    return SurgeryProcedureNote(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      patientId: PatientFileMetadataParseHelpers.requireString(map, 'patient_id'),
      patientName: patientName,
      procedureDate: DateTime(
        procedureDate.year,
        procedureDate.month,
        procedureDate.day,
      ),
      procedureType: _enumFromDb(
        ProcedureType.values,
        map['procedure_type'],
      ),
      bodyRegion: _enumFromDb(
        SurgeryBodyRegion.values,
        map['body_region'],
      ),
      side: _enumFromDb(SurgerySide.values, map['side']),
      diagnosis:
          PatientFileMetadataParseHelpers.optionalString(map['diagnosis']) ?? '-',
      procedureName:
          PatientFileMetadataParseHelpers.optionalString(map['procedure_name']) ??
              '-',
      anesthesiaType:
          PatientFileMetadataParseHelpers.optionalString(map['anesthesia_type']) ??
              '',
      asaScore:
          PatientFileMetadataParseHelpers.optionalString(map['asa_score']) ?? '',
      tourniquetUsed: map['tourniquet_used'] as bool?,
      implantOrMaterialInfo: PatientFileMetadataParseHelpers.optionalString(
            map['implant_or_material_info'],
          ) ??
          '',
      arthroscopyFindings: PatientFileMetadataParseHelpers.optionalString(
            map['arthroscopy_findings'],
          ) ??
          '',
      procedureDetails: PatientFileMetadataParseHelpers.optionalString(
            map['procedure_details'],
          ) ??
          '',
      complications:
          PatientFileMetadataParseHelpers.optionalString(map['complications']) ??
              '',
      postOpRecommendations: PatientFileMetadataParseHelpers.optionalString(
            map['post_op_recommendations'],
          ) ??
          '',
      physiotherapyStartRecommendation:
          PatientFileMetadataParseHelpers.optionalString(
                map['physiotherapy_start_recommendation'],
              ) ??
              '',
      controlSchedule:
          PatientFileMetadataParseHelpers.optionalString(map['control_schedule']) ??
              '',
      surgeonName:
          PatientFileMetadataParseHelpers.optionalString(map['surgeon_name']) ?? '',
      assistantInfo:
          PatientFileMetadataParseHelpers.optionalString(map['assistant_info']) ??
              '',
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes']) ?? '',
      createdByProfileId:
          PatientFileMetadataParseHelpers.optionalString(map['created_by']),
    );
  }

  static Map<String, dynamic> toUpdateRow(SurgeryProcedureNote note) {
    return {
      'procedure_date': _dateOnly(note.procedureDate),
      'procedure_type': note.procedureType.name,
      'body_region': note.bodyRegion.name,
      'side': note.side.name,
      'diagnosis': note.diagnosis.trim().isEmpty ? '-' : note.diagnosis.trim(),
      'procedure_name':
          note.procedureName.trim().isEmpty ? '-' : note.procedureName.trim(),
      'anesthesia_type': note.anesthesiaType.trim(),
      'asa_score': note.asaScore.trim(),
      'tourniquet_used': note.tourniquetUsed,
      'procedure_details': note.procedureDetails.trim(),
      'complications': note.complications.trim(),
      'implant_or_material_info': note.implantOrMaterialInfo.trim(),
      'arthroscopy_findings': note.arthroscopyFindings.trim(),
      'post_op_recommendations': note.postOpRecommendations.trim(),
      'physiotherapy_start_recommendation':
          note.physiotherapyStartRecommendation.trim(),
      'control_schedule': note.controlSchedule.trim(),
      'assistant_info': note.assistantInfo.trim(),
      'notes': note.notes.trim(),
    };
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required SurgeryProcedureNote note,
    String? createdByProfileId,
    String? recordedByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': note.patientId.trim(),
      'procedure_date': _dateOnly(note.procedureDate),
      'procedure_type': note.procedureType.name,
      'body_region': note.bodyRegion.name,
      'side': note.side.name,
      'diagnosis': note.diagnosis.trim().isEmpty ? '-' : note.diagnosis.trim(),
      'procedure_name':
          note.procedureName.trim().isEmpty ? '-' : note.procedureName.trim(),
      'anesthesia_type': note.anesthesiaType.trim(),
      'asa_score': note.asaScore.trim(),
      'tourniquet_used': note.tourniquetUsed,
      'procedure_details': note.procedureDetails.trim(),
      'complications': note.complications.trim(),
      'implant_or_material_info': note.implantOrMaterialInfo.trim(),
      'arthroscopy_findings': note.arthroscopyFindings.trim(),
      'post_op_recommendations': note.postOpRecommendations.trim(),
      'physiotherapy_start_recommendation':
          note.physiotherapyStartRecommendation.trim(),
      'control_schedule': note.controlSchedule.trim(),
      'surgeon_name': (recordedByDisplay?.trim().isNotEmpty == true
              ? recordedByDisplay!.trim()
              : note.surgeonName.trim()),
      'assistant_info': note.assistantInfo.trim(),
      'notes': note.notes.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      if (recordedByDisplay != null && recordedByDisplay.trim().isNotEmpty)
        'recorded_by_display': recordedByDisplay.trim(),
    };
  }

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const SurgeryProcedureNoteRepositoryException(
      SurgeryProcedureNoteRepositoryFailure.invalidRow,
    );
  }
}
