import '../models/prescription.dart';
import 'prescription_repository_failure.dart';

abstract final class PrescriptionRemoteMapper {
  static const table = 'prescriptions';

  static const listSelectColumns =
      'id, tenant_id, patient_id, clinical_encounter_id, status, diagnosis, '
      'medications, additional_notes, created_by, created_by_display, '
      'created_at, updated_at, patients(first_name, last_name)';

  static Prescription fromRow(Map<String, dynamic> row) {
    return Prescription(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: _embeddedPatientFullName(row['patients']) ?? 'Hasta',
      clinicalEncounterId: _optionalString(row['clinical_encounter_id']),
      createdAt: _requireDateTime(row['created_at']),
      updatedAt: _optionalDateTime(row['updated_at']),
      createdBy: _optionalString(row['created_by_display']) ?? '',
      status: _enumFromDb(PrescriptionStatus.values, row['status']),
      diagnosis: _optionalString(row['diagnosis']) ?? '',
      medications: _medicationsFromJson(row['medications']),
      additionalNotes: _optionalString(row['additional_notes']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required Prescription prescription,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': prescription.patientId.trim(),
      if (prescription.clinicalEncounterId?.trim().isNotEmpty == true)
        'clinical_encounter_id': prescription.clinicalEncounterId!.trim(),
      'status': prescription.status.name,
      'diagnosis': prescription.diagnosis.trim(),
      'medications': prescription.medications.map(_medicationToJson).toList(),
      if (prescription.additionalNotes?.trim().isNotEmpty == true)
        'additional_notes': prescription.additionalNotes!.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : prescription.createdBy.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(Prescription prescription) {
    return {
      'patient_id': prescription.patientId.trim(),
      if (prescription.clinicalEncounterId?.trim().isNotEmpty == true)
        'clinical_encounter_id': prescription.clinicalEncounterId!.trim()
      else
        'clinical_encounter_id': null,
      'status': prescription.status.name,
      'diagnosis': prescription.diagnosis.trim(),
      'medications': prescription.medications.map(_medicationToJson).toList(),
      'additional_notes': prescription.additionalNotes?.trim().isNotEmpty == true
          ? prescription.additionalNotes!.trim()
          : null,
    };
  }

  static Map<String, dynamic> _medicationToJson(PrescriptionMedication med) {
    return {
      'name': med.name,
      'dose': med.dose,
      'frequency': med.frequency,
      'duration': med.duration,
      if (med.notes != null && med.notes!.trim().isNotEmpty)
        'notes': med.notes!.trim(),
      if (med.boxCount != null) 'boxCount': med.boxCount,
    };
  }

  static List<PrescriptionMedication> _medicationsFromJson(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.invalidRow,
      );
    }
    return raw.map((item) {
      if (item is! Map) {
        throw const PrescriptionRepositoryException(
          PrescriptionRepositoryFailure.invalidRow,
        );
      }
      return PrescriptionMedication(
        name: _optionalString(item['name']) ?? '',
        dose: _optionalString(item['dose']) ?? '',
        frequency: _optionalString(item['frequency']) ?? '',
        duration: _optionalString(item['duration']) ?? '',
        notes: _optionalString(item['notes']),
        boxCount: _optionalInt(item['boxCount']),
      );
    }).toList();
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.invalidRow,
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
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.invalidRow,
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
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const PrescriptionRepositoryException(
      PrescriptionRepositoryFailure.invalidRow,
    );
  }
}
