import 'patient_file_metadata_repository_failure.dart';

/// DTO satır parse — kontrollü [PatientFileMetadataRepositoryException].
abstract final class PatientFileMetadataParseHelpers {
  static String requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidRow,
      );
    }
    return s;
  }

  static String? optionalString(Object? value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static int? optionalInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime requireDateTime(Object? value) {
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static DateTime? optionalDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, Object?> coerceMetadataMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return Map<String, Object?>.from(raw);
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry('$k', v));
    }
    return {};
  }
}
