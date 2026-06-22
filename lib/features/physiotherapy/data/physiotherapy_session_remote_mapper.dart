import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/physiotherapy_session_note.dart';
import 'physiotherapy_session_repository_failure.dart';

/// `physiotherapy_sessions` tablosu ↔ [PhysiotherapySessionNote] map.
abstract final class PhysiotherapySessionRemoteMapper {
  static const String table = 'physiotherapy_sessions';

  static const String defaultStatus = 'kayitli';

  static const String listSelectColumns =
      'id, tenant_id, referral_id, patient_id, physiotherapist_profile_id, '
      'session_date, status, pain_score, range_of_motion, strength, '
      'functional_status, exercises_performed, adherence, warning_signs, '
      'return_to_sport_stage, doctor_notification_needed, notes, next_plan, '
      'created_at, '
      'patients(first_name, last_name), '
      'physiotherapist:profiles!physiotherapist_profile_id(display_name)';

  static PhysiotherapySessionNote fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final patientName = _embeddedPatientFullName(map['patients']) ?? 'Hasta';
    final physioName =
        _embeddedDisplayName(map['physiotherapist']) ?? 'Fizyoterapist';

    return PhysiotherapySessionNote(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      patientId: PatientFileMetadataParseHelpers.requireString(map, 'patient_id'),
      patientName: patientName,
      sessionDate: PatientFileMetadataParseHelpers.requireDateTime(
        map['session_date'],
      ),
      physiotherapistName: physioName,
      painScore: _painScoreFromDb(map['pain_score']),
      rangeOfMotionSummary:
          PatientFileMetadataParseHelpers.optionalString(map['range_of_motion']) ??
              '',
      strengthSummary:
          PatientFileMetadataParseHelpers.optionalString(map['strength']) ?? '',
      functionalAssessment:
          PatientFileMetadataParseHelpers.optionalString(map['functional_status']) ??
              '',
      exercisesPerformed:
          PatientFileMetadataParseHelpers.optionalString(
                map['exercises_performed'],
              ) ??
              '',
      homeProgramCompliance:
          PatientFileMetadataParseHelpers.optionalString(map['adherence']) ??
              'Bilinmiyor',
      warningSigns:
          PatientFileMetadataParseHelpers.optionalString(map['warning_signs']) ??
              '',
      returnToSportStage: _returnStageFromDb(map['return_to_sport_stage']),
      doctorNotificationNeeded: map['doctor_notification_needed'] == true,
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes']) ?? '',
      referralId: PatientFileMetadataParseHelpers.requireString(
        map,
        'referral_id',
      ),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required PhysiotherapySessionNote session,
    required String physiotherapistProfileId,
  }) {
    final referralId = session.referralId?.trim() ?? '';
    if (referralId.isEmpty) {
      throw const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.validation,
      );
    }

    return {
      'tenant_id': tenantId,
      'referral_id': referralId,
      'patient_id': session.patientId.trim(),
      'physiotherapist_profile_id': physiotherapistProfileId,
      'session_date': session.sessionDate.toUtc().toIso8601String(),
      'status': defaultStatus,
      'pain_score': session.painScore,
      'range_of_motion': _nullableTrim(session.rangeOfMotionSummary),
      'strength': _nullableTrim(session.strengthSummary),
      'functional_status': _nullableTrim(session.functionalAssessment),
      'exercises_performed': _nullableTrim(session.exercisesPerformed),
      'adherence': _nullableTrim(session.homeProgramCompliance),
      'warning_signs': _nullableTrim(session.warningSigns),
      'return_to_sport_stage': session.returnToSportStage.name,
      'doctor_notification_needed': session.doctorNotificationNeeded,
      'notes': _nullableTrim(session.notes),
      'next_plan': null,
    };
  }

  static int _painScoreFromDb(Object? raw) {
    if (raw == null) return 0;
    if (raw is int) return raw.clamp(0, 10);
    if (raw is num) return raw.round().clamp(0, 10);
    final parsed = int.tryParse(raw.toString());
    if (parsed == null) return 0;
    return parsed.clamp(0, 10);
  }

  static ReturnToSportStage _returnStageFromDb(Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      return ReturnToSportStage.uygun_degil;
    }
    for (final stage in ReturnToSportStage.values) {
      if (stage.name == name) return stage;
    }
    throw const PhysiotherapySessionRepositoryException(
      PhysiotherapySessionRepositoryFailure.invalidRow,
    );
  }

  static String? _nullableTrim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

  static String? _embeddedDisplayName(dynamic value) {
    if (value is Map) {
      final name = value['display_name']?.toString().trim() ?? '';
      return name.isEmpty ? null : name;
    }
    return null;
  }
}
