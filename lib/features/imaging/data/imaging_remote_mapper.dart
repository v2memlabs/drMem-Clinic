import '../models/imaging_note.dart';
import 'imaging_repository_failure.dart';

abstract final class ImagingRemoteMapper {
  static const String table = 'imaging_notes';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, imaging_type, imaging_date, imaging_center, '
      'body_region, side, report_summary, doctor_comment, '
      'comparison_with_previous, related_diagnosis, related_visit_date, '
      'attached_file_name, created_by, created_at, patients(first_name, last_name)';

  static ImagingNote fromRow(Map<String, dynamic> row) {
    final patientName = _embeddedPatientFullName(row['patients']) ?? 'Hasta';
    final imagingDate = _requireDateTime(row['imaging_date']);
    final createdAt = _requireDateTime(row['created_at']);

    return ImagingNote(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: patientName,
      createdAt: createdAt,
      imagingType: _enumFromDb(ImagingType.values, row['imaging_type']),
      imagingDate: DateTime(
        imagingDate.year,
        imagingDate.month,
        imagingDate.day,
      ),
      imagingCenter: _optionalString(row['imaging_center']) ?? '',
      bodyRegion: _enumFromDb(ImagingBodyRegion.values, row['body_region']),
      side: _enumFromDb(ImagingSide.values, row['side']),
      reportSummary: _optionalString(row['report_summary']) ?? '',
      doctorComment: _optionalString(row['doctor_comment']) ?? '',
      comparisonWithPrevious:
          _optionalString(row['comparison_with_previous']) ?? '',
      relatedDiagnosis: _optionalString(row['related_diagnosis']) ?? '',
      relatedVisitDate: _optionalString(row['related_visit_date']),
      attachedFileName: _optionalString(row['attached_file_name']),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required ImagingNote note,
    String? createdByProfileId,
    String? recordedByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': note.patientId.trim(),
      'imaging_type': note.imagingType.name,
      'imaging_date': _dateOnly(note.imagingDate),
      'imaging_center': note.imagingCenter.trim(),
      'body_region': note.bodyRegion.name,
      'side': note.side.name,
      'report_summary': note.reportSummary.trim(),
      'doctor_comment': note.doctorComment.trim(),
      'comparison_with_previous': note.comparisonWithPrevious.trim(),
      'related_diagnosis': note.relatedDiagnosis.trim(),
      if (note.relatedVisitDate?.trim().isNotEmpty == true)
        'related_visit_date': note.relatedVisitDate!.trim(),
      if (note.attachedFileName?.trim().isNotEmpty == true)
        'attached_file_name': note.attachedFileName!.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      if (recordedByDisplay?.trim().isNotEmpty == true)
        'recorded_by_display': recordedByDisplay!.trim(),
    };
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
      throw const ImagingRepositoryException(
          ImagingRepositoryFailure.invalidRow);
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
      throw const ImagingRepositoryException(
          ImagingRepositoryFailure.invalidRow);
    }
    return parsed;
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
      throw const ImagingRepositoryException(
          ImagingRepositoryFailure.invalidRow);
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const ImagingRepositoryException(ImagingRepositoryFailure.invalidRow);
  }
}
