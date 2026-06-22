import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_repository_failure.dart';

/// `physiotherapy_referrals` tablosu ↔ [PhysiotherapyReferral] map.
abstract final class PhysiotherapyReferralRemoteMapper {
  static const String table = 'physiotherapy_referrals';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, clinical_encounter_id, appointment_id, '
      'referred_by_profile_id, assigned_physiotherapist_profile_id, '
      'reason, body_region, side, priority, status, planned_start_date, '
      'treatment_goal, precautions, allowed_activities, restricted_activities, '
      'target_return_date, notes_safe, doctor_summary, created_at, '
      'patients(first_name, last_name), '
      'referred_by:profiles!referred_by_profile_id(display_name), '
      'assigned_physiotherapist:profiles!assigned_physiotherapist_profile_id(display_name)';

  static PhysiotherapyReferral fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final patientName = _embeddedPatientFullName(map['patients']) ?? 'Hasta';
    final referredBy =
        _embeddedDisplayName(map['referred_by']) ?? 'Yönlendiren hekim';
    final assignedName = _embeddedDisplayName(map['assigned_physiotherapist']);
    final physioName = (assignedName == null || assignedName.isEmpty)
        ? 'Atanacak'
        : assignedName;

    return PhysiotherapyReferral(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      patientId: PatientFileMetadataParseHelpers.requireString(map, 'patient_id'),
      patientName: patientName,
      referredAt: PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
      referredBy: referredBy,
      physiotherapistName: physioName,
      assignedPhysiotherapistProfileId:
          PatientFileMetadataParseHelpers.optionalString(
        map['assigned_physiotherapist_profile_id'],
      ),
      appointmentId: PatientFileMetadataParseHelpers.optionalString(
        map['appointment_id'],
      ),
      diagnosisSummary:
          PatientFileMetadataParseHelpers.optionalString(map['reason']) ?? '',
      treatmentGoal: PatientFileMetadataParseHelpers.optionalString(
            map['treatment_goal'],
          ) ??
          '',
      precautions:
          PatientFileMetadataParseHelpers.optionalString(map['precautions']) ??
              '',
      allowedActivities: PatientFileMetadataParseHelpers.optionalString(
            map['allowed_activities'],
          ) ??
          '',
      restrictedActivities: PatientFileMetadataParseHelpers.optionalString(
            map['restricted_activities'],
          ) ??
          '',
      targetReturnToSportDate: PatientFileMetadataParseHelpers.optionalDateTime(
        map['target_return_date'],
      ),
      status: _statusFromDb(map['status']),
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes_safe']) ??
          '',
      clinicalEncounterId: PatientFileMetadataParseHelpers.optionalString(
        map['clinical_encounter_id'],
      ),
      plannedStartDate: PatientFileMetadataParseHelpers.optionalDateTime(
        map['planned_start_date'],
      ),
      doctorSummary: PatientFileMetadataParseHelpers.optionalString(
            map['doctor_summary'],
          ) ??
          '',
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required PhysiotherapyReferral referral,
    required String referredByProfileId,
    String? assignedPhysiotherapistProfileId,
  }) {
    final assignedProfileId = () {
      if (assignedPhysiotherapistProfileId != null &&
          assignedPhysiotherapistProfileId.trim().isNotEmpty) {
        return assignedPhysiotherapistProfileId.trim();
      }
      final fromReferral = referral.assignedPhysiotherapistProfileId?.trim();
      if (fromReferral != null && fromReferral.isNotEmpty) {
        return fromReferral;
      }
      return null;
    }();

    return {
      'tenant_id': tenantId,
      'patient_id': referral.patientId.trim(),
      if (referral.clinicalEncounterId != null &&
          referral.clinicalEncounterId!.trim().isNotEmpty)
        'clinical_encounter_id': referral.clinicalEncounterId!.trim(),
      'referred_by_profile_id': referredByProfileId,
      if (assignedProfileId != null)
        'assigned_physiotherapist_profile_id': assignedProfileId,
      'reason': referral.diagnosisSummary.trim(),
      'status': referral.status.name,
      'treatment_goal': _nullableTrim(referral.treatmentGoal),
      'precautions': _nullableTrim(referral.precautions),
      'allowed_activities': _nullableTrim(referral.allowedActivities),
      'restricted_activities': _nullableTrim(referral.restrictedActivities),
      if (referral.targetReturnToSportDate != null)
        'target_return_date':
            _dateOnlyString(referral.targetReturnToSportDate!),
      'notes_safe': null,
      'doctor_summary': _nullableTrim(
        referral.doctorSummary.isNotEmpty
            ? referral.doctorSummary
            : referral.notes,
      ),
      'priority': 'normal',
    };
  }

  static Map<String, dynamic> toSafeUpdateRow(
    PhysiotherapyReferralSafeUpdate update,
  ) {
    final row = <String, dynamic>{};
    if (update.status != null) {
      row['status'] = update.status!.name;
    }
    if (update.notesSafe != null) {
      final trimmed = update.notesSafe!.trim();
      row['notes_safe'] = trimmed.isEmpty ? null : trimmed;
    }
    if (update.plannedStartDate != null) {
      row['planned_start_date'] = _dateOnlyString(update.plannedStartDate!);
    }
    if (update.assignedPhysiotherapistProfileId != null) {
      final trimmed = update.assignedPhysiotherapistProfileId!.trim();
      row['assigned_physiotherapist_profile_id'] =
          trimmed.isEmpty ? null : trimmed;
    }
    if (update.appointmentId != null) {
      final trimmed = update.appointmentId!.trim();
      row['appointment_id'] = trimmed.isEmpty ? null : trimmed;
    }
    return row;
  }

  static String? _nullableTrim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _dateOnlyString(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static ReferralStatus _statusFromDb(Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.invalidRow,
      );
    }
    for (final status in ReferralStatus.values) {
      if (status.name == name) return status;
    }
    throw const PhysiotherapyReferralRepositoryException(
      PhysiotherapyReferralRepositoryFailure.invalidRow,
    );
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
