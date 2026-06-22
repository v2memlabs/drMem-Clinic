import '../models/appointment.dart';
import 'appointment_datetime_helper.dart';

/// Takvim görünümü — hafta şeridi ve gün normalizasyonu.
abstract final class AppointmentCalendarHelper {
  static const _shortWeekdays = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  static String shortWeekdayLabel(DateTime day) =>
      _shortWeekdays[normalize(day).weekday - 1];

  /// Y/m/d — saat bileşenleri sıfırlanır.
  static DateTime normalize(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      normalize(a) == normalize(b);

  /// Pazartesi başlangıçlı hafta.
  static DateTime mondayWeekStart(DateTime day) {
    final d = normalize(day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static List<DateTime> daysInWeek(DateTime weekStart) {
    final start = mondayWeekStart(weekStart);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Hafta kaydırıldığında aynı hafta gününü (ör. Perşembe) korur.
  static DateTime sameWeekdayInWeek(DateTime weekStart, int weekday) {
    final days = daysInWeek(weekStart);
    return days.firstWhere(
      (d) => d.weekday == weekday,
      orElse: () => days.first,
    );
  }

  static DateTime istanbulToday() =>
      AppointmentDateTimeHelper.istanbulCalendarToday();

  static bool isToday(DateTime day) => isSameDay(day, istanbulToday());

  static bool appointmentOnDay(Appointment appointment, DateTime day) {
    final local = appointment.appointmentDateTime.toLocal();
    return isSameDay(
      DateTime(local.year, local.month, local.day),
      day,
    );
  }
}
