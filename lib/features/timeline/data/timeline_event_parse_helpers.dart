import 'timeline_repository_failure.dart';

/// Timeline RPC satır parse — kontrollü [TimelineRepositoryException].
abstract final class TimelineEventParseHelpers {
  static String requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.invalidRow,
      );
    }
    return s;
  }

  static String? optionalString(Object? value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static DateTime requireDateTime(Object? value) {
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.invalidRow,
      );
    }
    return parsed;
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
