/// Muayene `encounter_date` — UTC saklama / yerel gösterim (harici TZ paketi yok).
abstract final class ClinicalEncounterDateTimeHelper {
  static DateTime localDateTimeToUtc(DateTime local) {
    if (local.isUtc) return local;
    return local.toUtc();
  }

  static DateTime parseFromDb(dynamic value) {
    if (value is DateTime) return value.toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }

  static String toUtcIsoString(DateTime dateTime) {
    return localDateTimeToUtc(dateTime).toIso8601String();
  }

  static DateTime toLocalForDisplay(DateTime utc) {
    return utc.toLocal();
  }
}
