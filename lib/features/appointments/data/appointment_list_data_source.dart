import '../../../core/data/repository_registry.dart';
import '../models/appointment.dart';
import 'appointment_calendar_helper.dart';
import 'appointment_calendar_load_result.dart';
import 'appointment_list_filters.dart';
import 'appointment_list_load_result.dart';
import 'appointment_list_user_messages.dart';
import 'appointment_repository_failure.dart';

/// Randevu listesi — [RepositoryRegistry.appointmentsAsync].
abstract final class AppointmentListDataSource {
  static Future<AppointmentListLoadResult> load({
    required String period,
    String? patientId,
    required String search,
  }) async {
    try {
      final repo = RepositoryRegistry.appointmentsAsync;
      final q = search.trim();
      final hasPatient = patientId != null && patientId.isNotEmpty;

      final List<Appointment> list;

      if (q.isNotEmpty) {
        list = _afterSearch(
          await repo.search(q),
          period: period,
          patientId: patientId,
          hasPatient: hasPatient,
        );
      } else if (hasPatient) {
        list = AppointmentListFilters.applyPeriod(
          await repo.getByPatientId(patientId),
          period,
        );
      } else if (period == 'today') {
        list = await repo.getToday();
      } else if (period == 'week') {
        list = await repo.getThisWeek();
      } else {
        list = await repo.getAll();
      }

      return AppointmentListLoadResult.success(list);
    } on AppointmentRepositoryException catch (e) {
      return AppointmentListLoadResult.failure(
        AppointmentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return AppointmentListLoadResult.failure(
        AppointmentListUserMessages.genericLoadFailure,
      );
    }
  }

  static List<Appointment> _afterSearch(
    List<Appointment> list, {
    required String period,
    String? patientId,
    required bool hasPatient,
  }) {
    if (hasPatient) {
      list = list.where((a) => a.patientId == patientId).toList();
    }
    return AppointmentListFilters.applyPeriod(list, period);
  }

  /// Tip 2 takvim görünümü — seçili gün listesi + hafta yoğunlukları.
  static Future<AppointmentCalendarLoadResult> loadCalendarView({
    required DateTime selectedDay,
    required DateTime weekStart,
    String? patientId,
    required String search,
  }) async {
    try {
      final repo = RepositoryRegistry.appointmentsAsync;
      final q = search.trim();
      final hasPatient = patientId != null && patientId.isNotEmpty;
      final calendarDay = AppointmentCalendarHelper.normalize(selectedDay);
      final weekDays = AppointmentCalendarHelper.daysInWeek(weekStart);

      List<Appointment> dayAppointments;
      Map<DateTime, int> weekCounts;

      if (q.isNotEmpty) {
        var list = await repo.search(q);
        if (hasPatient) {
          list = list.where((a) => a.patientId == patientId).toList();
        }
        dayAppointments = _filterToDay(list, calendarDay);
        weekCounts = _countByDays(list, weekDays);
      } else if (hasPatient) {
        final all = await repo.getByPatientId(patientId);
        dayAppointments = _filterToDay(all, calendarDay);
        weekCounts = _countByDays(all, weekDays);
      } else {
        dayAppointments = await repo.getForCalendarDay(calendarDay);
        final results = await Future.wait(
          weekDays.map(repo.getForCalendarDay),
        );
        weekCounts = {
          for (var i = 0; i < weekDays.length; i++)
            AppointmentCalendarHelper.normalize(weekDays[i]): results[i].length,
        };
      }

      dayAppointments.sort(
        (a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime),
      );

      return AppointmentCalendarLoadResult.success(
        appointments: dayAppointments,
        weekCounts: weekCounts,
      );
    } on AppointmentRepositoryException catch (e) {
      return AppointmentCalendarLoadResult.failure(
        AppointmentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return AppointmentCalendarLoadResult.failure(
        AppointmentListUserMessages.genericLoadFailure,
      );
    }
  }

  static List<Appointment> _filterToDay(
    List<Appointment> list,
    DateTime day,
  ) {
    return list
        .where((a) => AppointmentCalendarHelper.appointmentOnDay(a, day))
        .toList();
  }

  static Map<DateTime, int> _countByDays(
    List<Appointment> list,
    List<DateTime> days,
  ) {
    return {
      for (final day in days)
        AppointmentCalendarHelper.normalize(day): list
            .where((a) => AppointmentCalendarHelper.appointmentOnDay(a, day))
            .length,
    };
  }
}
