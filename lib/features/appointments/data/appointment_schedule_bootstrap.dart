import 'appointment_availability_data_source.dart';
import 'appointment_calendar_helper.dart';
import '../models/clinic_schedule_config.dart';

/// Randevu ekranları — ilk seçilebilir gün (persisted klinik takvimi).
abstract final class AppointmentScheduleBootstrap {
  static Future<DateTime> resolveInitialDay({DateTime? preferredDay}) async {
    final base = preferredDay ?? AppointmentCalendarHelper.istanbulToday();
    final calendar = DateTime(base.year, base.month, base.day);

    try {
      final config =
          await AppointmentAvailabilityDataSource.loadScheduleConfig();
      if (config.isActiveWeekday(calendar.weekday) &&
          !config.isClosedDate(calendar)) {
        return calendar;
      }
      return config.firstSelectableDay(from: calendar);
    } catch (_) {
      return ClinicScheduleConfig.defaultClinic()
          .firstSelectableDay(from: calendar);
    }
  }
}
