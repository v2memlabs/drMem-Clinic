/// Randevu `appointment_at` — UTC saklama / yerel gösterim (harici TZ paketi yok).
///
/// Türkiye sabit UTC+3 (DST yok) kabulü ile İstanbul takvim günü aralıkları üretilir.
/// Form birleştirme (cihaz local) için [localDateTimeToUtcIso] kullanılır.
abstract final class AppointmentDateTimeHelper {
  static const Duration istanbulOffsetFromUtc = Duration(hours: 3);

  /// Cihaz/yerel bileşenlerden UTC anı (form kayıt).
  static DateTime localDateTimeToUtc(DateTime local) {
    if (local.isUtc) return local;
    return local.toUtc();
  }

  /// DB ISO → yerel gösterim için UTC anı.
  static DateTime parseFromDb(dynamic value) {
    if (value is DateTime) return value.toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }

  /// UTC anı → ISO8601 (insert/update).
  static String toUtcIsoString(DateTime dateTime) {
    return localDateTimeToUtc(dateTime).toIso8601String();
  }

  /// UTC anı → UI listeleme için yerel.
  static DateTime toLocalForDisplay(DateTime utc) {
    return utc.toLocal();
  }

  /// Takvim günü (y,m,d) İstanbul 00:00 → UTC instant.
  static DateTime istanbulDayStartUtc(DateTime calendarDay) {
    final y = calendarDay.year;
    final m = calendarDay.month;
    final d = calendarDay.day;
    return DateTime.utc(y, m, d).subtract(istanbulOffsetFromUtc);
  }

  /// Ertesi gün İstanbul 00:00 (exclusive üst sınır).
  static DateTime istanbulDayEndExclusiveUtc(DateTime calendarDay) {
    return istanbulDayStartUtc(calendarDay).add(const Duration(days: 1));
  }

  /// Şu anki İstanbul takvim günü (cihaz saati + sabit UTC+3).
  static DateTime istanbulCalendarToday() {
    final istanbulNow = DateTime.now().toUtc().add(istanbulOffsetFromUtc);
    return DateTime(istanbulNow.year, istanbulNow.month, istanbulNow.day);
  }

  /// Bugün (İstanbul) UTC aralığı — [start, end).
  static ({DateTime startUtc, DateTime endExclusiveUtc}) istanbulTodayRangeUtc() {
    final day = istanbulCalendarToday();
    return (
      startUtc: istanbulDayStartUtc(day),
      endExclusiveUtc: istanbulDayEndExclusiveUtc(day),
    );
  }

  /// Pazartesi başlangıçlı yerel hafta — mock liste ile uyumlu UTC aralığı.
  static ({DateTime startUtc, DateTime endExclusiveUtc}) localWeekRangeUtc({
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    final startLocal = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endLocal = startLocal.add(const Duration(days: 7));
    return (
      startUtc: localDateTimeToUtc(startLocal),
      endExclusiveUtc: localDateTimeToUtc(endLocal),
    );
  }
}
